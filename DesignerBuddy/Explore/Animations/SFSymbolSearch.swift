import Foundation

// MARK: - SF Symbol Search

/// Ranked, typo-tolerant search over SF Symbol names.
///
/// Symbol names are dot-delimited (`arrow.forward.circle.fill`) but people type
/// spaces and everyday words ("forward arrow", "settings", "trash can"). A plain
/// `contains(query)` over the raw name therefore misses almost every multi-word
/// query — "forward arrow" can never match "arrow.forward" — so both sides are
/// tokenized here and every query token is scored independently.
///
/// Matching runs in tiers, stopping at the first tier that produces symbols
/// satisfying *all* meaningful query tokens:
///
/// 1. Literal — exact token, token prefix, token substring, or a substring of the
///    name with separators stripped (so "arrowup" finds `arrow.up`).
/// 2. Synonym — "settings" → `gear`, "share" → `square.and.arrow.up`.
/// 3. Fuzzy — one or two typos per token, or a tight subsequence match, so
///    "chekmark" finds `checkmark` and "magnifing glass" finds `magnifyingglass`.
/// 4. Partial — nothing satisfied every token, so the best-covered symbols are
///    returned and flagged approximate rather than showing an empty state.
nonisolated enum SFSymbolSearch {

    // MARK: Results

    struct Results {
        /// Ranked matches, best first. Never truncated — callers decide how many to show.
        var symbols: [String]
        /// True when nothing matched the query literally and these are the closest
        /// alternatives (typo correction or partial coverage), so the UI can say so.
        var isApproximate: Bool

        static let none = Results(symbols: [], isApproximate: false)
    }

    // MARK: Entry Point

    /// Searches the whole symbol library using its prebuilt index.
    static func searchLibrary(_ rawQuery: String) -> Results {
        search(rawQuery, entries: libraryIndex, fallbackPool: SFSymbolLibrary.all)
    }

    /// Searches an arbitrary subset, such as one category's symbols.
    static func search(_ rawQuery: String, in pool: [String]) -> Results {
        search(rawQuery, entries: entries(for: pool), fallbackPool: pool)
    }

    /// An empty or punctuation-only query returns the pool unchanged, so callers can
    /// use this for "no query" browsing too.
    private static func search(_ rawQuery: String, entries: [Entry], fallbackPool: [String]) -> Results {
        let query = Query(rawQuery)
        guard !query.tokens.isEmpty else {
            return Results(symbols: fallbackPool, isApproximate: false)
        }

        // The literal pass is roughly an order of magnitude cheaper than the fuzzy
        // one, and it satisfies the overwhelming majority of queries. Only pay for
        // edit-distance work when it comes up empty.
        var pass = score(entries, query: query, allowFuzzy: false)
        var isApproximate = false
        if pass.complete.isEmpty {
            pass = score(entries, query: query, allowFuzzy: true)
            isApproximate = true
        }

        let hits = pass.complete.isEmpty ? pass.partial : pass.complete
        guard !hits.isEmpty else { return .none }
        return Results(symbols: rank(hits), isApproximate: isApproximate)
    }

    // MARK: Scoring

    private struct Hit {
        let name: String
        let score: Int
    }

    private struct Pass {
        var complete: [Hit] = []
        var partial: [Hit] = []
    }

    private static func score(_ entries: [Entry], query: Query, allowFuzzy: Bool) -> Pass {
        var pass = Pass()

        for entry in entries {
            var total = 0
            var matchedCount = 0
            var missedRequired = false

            for token in query.tokens {
                guard let tokenScore = score(token: token, against: entry, allowFuzzy: allowFuzzy) else {
                    // Filler words ("icon", "symbol") never disqualify a symbol; they
                    // just don't contribute. Everything else must land somewhere.
                    if query.required.contains(token) { missedRequired = true }
                    continue
                }
                matchedCount += 1
                total += tokenScore
            }

            guard matchedCount > 0 else { continue }

            if missedRequired {
                // Keep as a partial match, but well below anything fully covered.
                total = total * matchedCount / max(1, query.required.count * 4)
            }

            total += bonuses(for: entry, query: query)

            let hit = Hit(name: entry.name, score: total)
            if missedRequired {
                pass.partial.append(hit)
            } else {
                pass.complete.append(hit)
            }
        }

        return pass
    }

    /// Best score for a single query token against one symbol, or `nil` if it
    /// doesn't appear at all.
    private static func score(token: String, against entry: Entry, allowFuzzy: Bool) -> Int? {
        if let literal = literalScore(token: token, against: entry) { return literal }

        // "settings" → gear, "share" → square.and.arrow.up
        if let phrases = synonyms[token] {
            var best = 0
            for phrase in phrases {
                best = max(best, score(phrase: phrase, against: entry) ?? 0)
            }
            if best > 0 { return best }
        }

        // "arrows" → arrow, "bubbles" → bubble
        if token.count >= 4, token.hasSuffix("s") {
            let singular = String(token.dropLast())
            if let singularScore = literalScore(token: singular, against: entry) {
                return max(1, singularScore - Weight.pluralPenalty)
            }
        }

        guard allowFuzzy, token.count >= 4 else { return nil }
        return fuzzyScore(token: token, against: entry)
    }

    private static func literalScore(token: String, against entry: Entry) -> Int? {
        var best: Int?
        for (index, symbolToken) in entry.tokens.enumerated() {
            var score: Int
            if symbolToken == token {
                score = Weight.exactToken
            } else if symbolToken.hasPrefix(token) {
                score = Weight.prefixToken
            } else if symbolToken.contains(token) {
                score = Weight.substringToken
            } else {
                continue
            }
            // The leading token is the symbol's subject ("arrow" in arrow.up.circle).
            if index == 0 { score += Weight.headBonus }
            if best == nil || score > best! { best = score }
        }
        if let best { return best }

        // Separator-free typing: "arrowup", "squareandarrowup".
        if token.count >= 3, entry.squashed.contains(token) { return Weight.squashedSubstring }
        return nil
    }

    /// A synonym phrase such as `square.and.arrow.up` only counts when every one of
    /// its parts is present, and it scores below a literal hit on the same symbol.
    private static func score(phrase: [String], against entry: Entry) -> Int? {
        var total = 0
        for part in phrase {
            guard let score = literalScore(token: part, against: entry) else { return nil }
            total += score
        }
        return Int(Double(total / phrase.count) * Weight.synonymFactor)
    }

    private static func fuzzyScore(token: String, against entry: Entry) -> Int? {
        let needle = Array(token.utf8)
        let tolerance = token.count >= 7 ? 2 : 1

        for symbolToken in entry.tokens {
            // Cheap length gate before the DP table.
            guard abs(symbolToken.utf8.count - needle.count) <= tolerance else { continue }
            if editDistance(needle, Array(symbolToken.utf8), tolerance: tolerance) <= tolerance {
                return Weight.fuzzyToken
            }
        }

        // Dropped or transposed letters inside a long word: "magnifing" in
        // "magnifyingglass". Bounded span keeps this from matching scattered letters.
        for symbolToken in entry.tokens {
            if let span = subsequenceSpan(needle, in: Array(symbolToken.utf8)),
               span <= needle.count + Weight.maxSubsequenceSlack {
                return Weight.subsequenceToken
            }
        }

        return nil
    }

    private static func bonuses(for entry: Entry, query: Query) -> Int {
        var total = 0

        if entry.squashed == query.squashed {
            total += Weight.exactNameBonus          // typed the symbol's name outright
        } else if entry.name.hasPrefix(query.dotted + ".") {
            // "arrow.up" → arrow.up.circle.fill. The trailing dot keeps this on token
            // boundaries, so "home" doesn't rank `homepod` over `house`.
            total += Weight.namePrefixBonus
        }

        // Prefer the plainest symbol that satisfies the query: `arrow.forward` should
        // outrank `pencil.tip.crop.circle.badge.arrow.forward.fill`.
        total -= Weight.extraTokenPenalty * max(0, entry.tokens.count - query.tokens.count)
        total -= entry.name.count / Weight.lengthPenaltyDivisor

        // Localized variants (`.ar`, `.hi`, `.rtl`) are ~14% of the library and are
        // rarely what someone browsing wants — demote, but keep them findable by name.
        if let locale = entry.localeSuffix, !query.tokenSet.contains(locale) {
            total -= Weight.localeVariantPenalty
        }

        return total
    }

    private static func rank(_ hits: [Hit]) -> [String] {
        hits.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.name.count != $1.name.count { return $0.name.count < $1.name.count }
            return $0.name < $1.name
        }
        .map(\.name)
    }

    // MARK: Weights

    private enum Weight {
        static let exactToken = 100
        static let prefixToken = 70
        static let substringToken = 40
        static let squashedSubstring = 25
        static let fuzzyToken = 20
        static let subsequenceToken = 16
        static let headBonus = 8
        static let pluralPenalty = 5
        static let synonymFactor = 0.75
        static let exactNameBonus = 1000
        static let namePrefixBonus = 300
        static let extraTokenPenalty = 2
        static let lengthPenaltyDivisor = 12
        static let localeVariantPenalty = 120
        static let maxSubsequenceSlack = 4
    }

    // MARK: Query

    private struct Query {
        let tokens: [String]
        /// Tokens that a symbol must satisfy. Filler words are dropped unless the
        /// query is nothing but filler.
        let required: Set<String>
        let tokenSet: Set<String>
        /// "forward arrow" → "forward.arrow"
        let dotted: String
        /// "forward arrow" → "forwardarrow"
        let squashed: String

        init(_ raw: String) {
            let normalized = SFSymbolSearch.normalize(raw)
            let tokens = normalized.split(separator: " ").map(String.init)
            self.tokens = tokens
            self.tokenSet = Set(tokens)
            let meaningful = tokens.filter { !SFSymbolSearch.fillerWords.contains($0) }
            self.required = Set(meaningful.isEmpty ? tokens : meaningful)
            self.dotted = tokens.joined(separator: ".")
            self.squashed = tokens.joined()
        }
    }

    /// Lowercases, strips diacritics, and turns every separator — dots, dashes,
    /// underscores, spaces — into a single space, so "Arrow.Up", "arrow-up" and
    /// "arrow up" all normalize identically.
    static func normalize(_ raw: String) -> String {
        let folded = raw.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                                 locale: nil)
        var out = ""
        out.reserveCapacity(folded.count)
        var pendingSeparator = false
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                if pendingSeparator, !out.isEmpty { out.append(" ") }
                pendingSeparator = false
                out.unicodeScalars.append(scalar)
            } else {
                pendingSeparator = true
            }
        }
        return out
    }

    /// Words people pad queries with that carry no matching signal.
    private static let fillerWords: Set<String> = [
        "icon", "icons", "symbol", "symbols", "sf", "glyph", "sign",
        "the", "a", "an", "of", "for", "with", "please",
    ]

    // MARK: Index

    private struct Entry {
        let name: String
        let tokens: [String]
        /// Name with separators removed, for "arrowup"-style typing.
        let squashed: String
        /// Trailing localization suffix (`ar`, `hi`, `rtl`, …) when present.
        let localeSuffix: String?
    }

    private static let localeSuffixes: Set<String> = [
        "ar", "he", "hi", "ja", "ko", "th", "zh", "ur",
        "bn", "gu", "kn", "ml", "mr", "or", "pa", "si", "ta", "te",
        "el", "ru", "my", "km", "lo", "am", "ka",
        "rtl", "ltr",
    ]

    private static func makeEntry(_ name: String) -> Entry {
        let tokens = normalize(name).split(separator: " ").map(String.init)
        var localeSuffix: String?
        if tokens.count > 1, let last = tokens.last, localeSuffixes.contains(last) {
            localeSuffix = last
        }
        return Entry(name: name,
                     tokens: tokens,
                     squashed: tokens.joined(),
                     localeSuffix: localeSuffix)
    }

    /// The full library, tokenized once. `static let` initialization is lazy and
    /// runs exactly once even under concurrent access.
    private static let libraryIndex: [Entry] = SFSymbolLibrary.all.map(SFSymbolSearch.makeEntry)

    /// Smaller pools (a category, a curated shortlist) are tokenized per search rather
    /// than looked up in the library index — a few hundred entries is far cheaper than
    /// forcing the whole 8,000-name index to build, which callers on the main thread
    /// would otherwise pay for on first keystroke.
    private static func entries(for pool: [String]) -> [Entry] {
        pool.map(makeEntry)
    }

    // MARK: Synonyms

    /// Everyday words → the symbol vocabulary Apple actually uses. Values are
    /// dot-phrases; every part must be present for the synonym to count.
    private static let synonyms: [String: [[String]]] = {
        let raw: [String: [String]] = [
            // Direction
            "forward": ["right"], "back": ["left", "backward"], "backward": ["left"],
            "next": ["right", "forward"], "previous": ["left", "backward"], "prev": ["left", "backward"],
            "expand": ["arrow.up.left.and.arrow.down.right"],
            "fullscreen": ["arrow.up.left.and.arrow.down.right"],
            "collapse": ["arrow.down.right.and.arrow.up.left"],
            "minimize": ["arrow.down.right.and.arrow.up.left"],

            // Actions
            "delete": ["trash", "xmark", "minus"], "remove": ["minus", "trash", "xmark"], "bin": ["trash"],
            "add": ["plus"], "new": ["plus"], "create": ["plus"],
            "close": ["xmark"], "cancel": ["xmark"], "dismiss": ["xmark"],
            "done": ["checkmark"], "tick": ["checkmark"], "confirm": ["checkmark"],
            "edit": ["pencil", "square.and.pencil"], "compose": ["square.and.pencil"], "write": ["pencil"],
            "share": ["square.and.arrow.up"], "download": ["arrow.down"], "upload": ["arrow.up"],
            "refresh": ["arrow.clockwise"], "reload": ["arrow.clockwise"],
            "sync": ["arrow.triangle.2.circlepath"], "loading": ["arrow.triangle.2.circlepath"],
            "spinner": ["arrow.triangle.2.circlepath"],
            "undo": ["arrow.uturn.backward"], "redo": ["arrow.uturn.forward"],
            "copy": ["doc.on.doc"], "duplicate": ["plus.square.on.square"],
            "paste": ["clipboard", "doc.on.clipboard"], "print": ["printer"],
            "send": ["paperplane"], "search": ["magnifyingglass"], "find": ["magnifyingglass"],
            "zoom": ["magnifyingglass"], "save": ["bookmark", "square.and.arrow.down"],
            "hide": ["eye.slash"], "show": ["eye"], "visible": ["eye"],
            "sort": ["arrow.up.arrow.down"], "filter": ["line.3.horizontal.decrease"],
            "logout": ["rectangle.portrait.and.arrow.right"],
            "signout": ["rectangle.portrait.and.arrow.right"],
            "login": ["rectangle.portrait.and.arrow.forward"],

            // Objects & concepts
            "settings": ["gear", "gearshape", "slider"], "preferences": ["gear", "gearshape"],
            "config": ["gear", "gearshape"],
            "image": ["photo"], "picture": ["photo"], "pic": ["photo"], "gallery": ["photo"],
            "user": ["person"], "profile": ["person"], "account": ["person"], "avatar": ["person"],
            "people": ["person"], "home": ["house"],
            "mail": ["envelope"], "email": ["envelope"], "inbox": ["tray"],
            "notification": ["bell"], "alert": ["exclamationmark", "bell"],
            "warning": ["exclamationmark"], "error": ["exclamationmark", "xmark"],
            "help": ["questionmark"], "favorite": ["heart", "star"], "like": ["heart"],
            "menu": ["line.3.horizontal"], "hamburger": ["line.3.horizontal"],
            "more": ["ellipsis"], "overflow": ["ellipsis"],
            "date": ["calendar"], "schedule": ["calendar"], "time": ["clock"],
            "location": ["location", "mappin"], "gps": ["location"],
            "mute": ["speaker.slash"], "volume": ["speaker"], "sound": ["speaker"],
            "audio": ["speaker", "waveform"], "call": ["phone"],
            "chat": ["bubble", "message"], "comment": ["bubble", "message"],
            "secure": ["lock"], "unlock": ["lock.open"], "password": ["lock", "key"],
            "shop": ["cart", "bag"], "buy": ["cart", "creditcard"], "payment": ["creditcard"],
            "money": ["dollarsign", "creditcard"],
            "graph": ["chart"], "analytics": ["chart"], "stats": ["chart"],
            "file": ["doc"], "document": ["doc"], "directory": ["folder"],
            "url": ["link"], "attachment": ["paperclip"], "attach": ["paperclip"],
            "grid": ["square.grid.2x2"], "list": ["list.bullet"],
            "dark": ["moon"], "night": ["moon"], "day": ["sun.max"],
        ]
        return raw.mapValues { phrases in
            phrases.map { $0.split(separator: ".").map(String.init) }
        }
    }()

    // MARK: String Distance

    /// Bounded Levenshtein: bails out as soon as every cell exceeds `tolerance`.
    private static func editDistance(_ lhs: [UInt8], _ rhs: [UInt8], tolerance: Int) -> Int {
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        var current = [Int](repeating: 0, count: rhs.count + 1)

        for i in 1...lhs.count {
            current[0] = i
            var rowMinimum = i
            for j in 1...rhs.count {
                let substitution = previous[j - 1] + (lhs[i - 1] == rhs[j - 1] ? 0 : 1)
                current[j] = min(previous[j] + 1, current[j - 1] + 1, substitution)
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > tolerance { return tolerance + 1 }
            swap(&previous, &current)
        }
        return previous[rhs.count]
    }

    /// Width of the window in `haystack` spanned by `needle`'s characters in order,
    /// or `nil` if they don't all appear.
    private static func subsequenceSpan(_ needle: [UInt8], in haystack: [UInt8]) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
        var index = 0
        var first: Int?
        var last = 0
        for (position, byte) in haystack.enumerated() where index < needle.count && byte == needle[index] {
            if first == nil { first = position }
            last = position
            index += 1
        }
        guard index == needle.count, let first else { return nil }
        return last - first + 1
    }
}

// MARK: - Picker Results

nonisolated extension SFSymbolSearch {

    /// Everything the symbol picker needs for one query, computed in one place so it
    /// can run off the main actor.
    struct PickerResults {
        /// Ranked and complete; the view pages through these rather than truncating.
        var symbols: [String]
        var isApproximate = false
        /// Showing the curated shortlist rather than search results.
        var isFeatured = false
        /// The category results were scoped to, if any.
        var category: SFSymbolCategory?
        /// How many symbols the whole library matches. Only filled in when a
        /// category-scoped search found nothing, so the UI can offer a way out
        /// instead of dead-ending on results that do exist.
        var libraryMatchCount = 0

        static let featured = PickerResults(symbols: SFSymbolLibrary.featured, isFeatured: true)
    }

    static func pickerResults(query: String, category: SFSymbolCategory?) -> PickerResults {
        guard !query.isEmpty else {
            // Nothing typed: browse the whole category, or the featured shortlist.
            guard let category else { return .featured }
            return PickerResults(symbols: category.searchPool, category: category)
        }

        guard let category else {
            let found = searchLibrary(query)
            return PickerResults(symbols: found.symbols, isApproximate: found.isApproximate)
        }

        let found = search(query, in: category.searchPool)
        let elsewhere = found.symbols.isEmpty ? searchLibrary(query).symbols.count : 0
        return PickerResults(symbols: found.symbols,
                             isApproximate: found.isApproximate,
                             category: category,
                             libraryMatchCount: elsewhere)
    }
}
