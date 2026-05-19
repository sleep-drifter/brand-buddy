import SwiftUI

// MARK: - SF Symbol Category

enum SFSymbolCategory: String, CaseIterable, Identifiable {
    case communication   = "Communication"
    case weather         = "Weather"
    case objectsTools    = "Objects & Tools"
    case devices         = "Devices"
    case gaming          = "Gaming"
    case connectivity    = "Connectivity"
    case transport       = "Transport"
    case human           = "Human"
    case nature          = "Nature"
    case editing         = "Editing"
    case textFormatting  = "Text Formatting"
    case multicolor      = "Multicolor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .communication:  return "message"
        case .weather:        return "cloud.sun"
        case .objectsTools:   return "hammer"
        case .devices:        return "iphone"
        case .gaming:         return "gamecontroller"
        case .connectivity:   return "wifi"
        case .transport:      return "car"
        case .human:          return "person"
        case .nature:         return "leaf"
        case .editing:        return "pencil"
        case .textFormatting: return "textformat"
        case .multicolor:     return "paintpalette"
        }
    }

    var symbolNames: [String] {
        switch self {
        case .communication:
            return [
                "message", "message.fill", "message.circle", "message.circle.fill",
                "message.badge", "message.badge.fill", "message.and.waveform", "message.and.waveform.fill",
                "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
                "bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill",
                "bubble.middle.top", "bubble.middle.top.fill", "bubble.middle.bottom", "bubble.middle.bottom.fill",
                "envelope", "envelope.fill", "envelope.circle", "envelope.circle.fill",
                "envelope.open", "envelope.open.fill", "envelope.badge", "envelope.badge.fill",
                "envelope.arrow.triangle.branch", "envelope.arrow.triangle.branch.fill",
                "phone", "phone.fill", "phone.circle", "phone.circle.fill",
                "phone.arrow.up.right", "phone.arrow.up.right.fill",
                "phone.arrow.down.left", "phone.arrow.down.left.fill",
                "phone.badge.plus", "phone.badge.plus.fill",
                "phone.connection", "phone.connection.fill",
                "video", "video.fill", "video.circle", "video.circle.fill",
                "video.slash", "video.slash.fill",
                "video.badge.plus", "video.badge.plus.fill",
                "video.badge.checkmark", "video.badge.checkmark.fill",
                "mic", "mic.fill", "mic.circle", "mic.circle.fill",
                "mic.slash", "mic.slash.fill", "mic.badge.plus",
                "bell", "bell.fill", "bell.circle", "bell.circle.fill",
                "bell.slash", "bell.slash.fill", "bell.badge", "bell.badge.fill",
                "bell.and.waves.left.and.right", "bell.and.waves.left.and.right.fill",
                "bell.badge.waveform", "bell.badge.waveform.fill",
                "megaphone", "megaphone.fill", "speaker.wave.1", "speaker.wave.2",
                "speaker.wave.3", "speaker.wave.3.fill", "speaker.slash", "speaker.slash.fill",
                "antenna.radiowaves.left.and.right", "antenna.radiowaves.left.and.right.slash",
                "shareplay", "shareplay.slash", "dot.radiowaves.left.and.right",
                "quote.bubble", "quote.bubble.fill",
                "text.bubble", "text.bubble.fill",
            ]
        case .weather:
            return [
                "sun.max", "sun.max.fill", "sun.min", "sun.min.fill",
                "sun.horizon", "sun.horizon.fill", "sunrise", "sunrise.fill",
                "sunset", "sunset.fill", "sun.dust", "sun.dust.fill",
                "sun.haze", "sun.haze.fill", "sun.rain", "sun.rain.fill",
                "sun.snow", "sun.snow.fill",
                "moon", "moon.fill", "moon.circle", "moon.circle.fill",
                "moon.stars", "moon.stars.fill", "moon.zzz", "moon.zzz.fill",
                "zzz", "sparkle", "sparkles", "star", "star.fill",
                "cloud", "cloud.fill", "cloud.drizzle", "cloud.drizzle.fill",
                "cloud.rain", "cloud.rain.fill", "cloud.heavyrain", "cloud.heavyrain.fill",
                "cloud.sun", "cloud.sun.fill", "cloud.sun.rain", "cloud.sun.rain.fill",
                "cloud.moon", "cloud.moon.fill", "cloud.moon.rain", "cloud.moon.rain.fill",
                "cloud.snow", "cloud.snow.fill", "cloud.hail", "cloud.hail.fill",
                "cloud.fog", "cloud.fog.fill", "cloud.sleet", "cloud.sleet.fill",
                "cloud.bolt", "cloud.bolt.fill", "cloud.bolt.rain", "cloud.bolt.rain.fill",
                "tornado", "tropicalstorm", "hurricane", "wind",
                "wind.snow", "snowflake", "thermometer.low", "thermometer.medium",
                "thermometer.high", "thermometer.sun", "thermometer.sun.fill",
                "humidity", "humidity.fill", "umbrella", "umbrella.fill",
                "umbrella.percent", "umbrella.percent.fill",
                "aqi.low", "aqi.medium", "aqi.high",
                "smoke", "smoke.fill", "bolt.horizontal", "bolt.horizontal.fill",
                "rainbow",
            ]
        case .objectsTools:
            return [
                "hammer", "hammer.fill", "hammer.circle", "hammer.circle.fill",
                "wrench", "wrench.fill", "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
                "screwdriver", "screwdriver.fill",
                "scissors", "scissors.circle", "scissors.circle.fill",
                "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill",
                "pencil", "pencil.circle", "pencil.circle.fill", "pencil.slash",
                "pencil.and.outline", "pencil.tip",
                "eraser", "eraser.fill",
                "ruler", "ruler.fill", "level", "level.fill",
                "magnifyingglass", "magnifyingglass.circle", "magnifyingglass.circle.fill",
                "loupe", "lasso", "lasso.badge.sparkles",
                "flashlight.on.fill", "flashlight.off.fill",
                "flashlight.slash", "flashlight.slash.fill",
                "lightbulb", "lightbulb.fill", "lightbulb.circle", "lightbulb.circle.fill",
                "lightbulb.slash", "lightbulb.slash.fill",
                "key", "key.fill", "key.horizontal", "key.horizontal.fill",
                "lock", "lock.fill", "lock.circle", "lock.circle.fill",
                "lock.open", "lock.open.fill", "lock.slash", "lock.slash.fill",
                "shield", "shield.fill", "shield.lefthalf.filled", "shield.slash",
                "tag", "tag.fill", "tag.circle", "tag.circle.fill",
                "flag", "flag.fill", "flag.circle", "flag.circle.fill",
                "flag.slash", "flag.slash.fill",
                "pin", "pin.fill", "pin.circle", "pin.circle.fill", "pin.slash", "pin.slash.fill",
                "mappin", "mappin.and.ellipse", "mappin.slash", "map", "map.fill",
                "globe", "globe.americas", "globe.americas.fill",
                "globe.europe.africa", "globe.europe.africa.fill",
                "globe.asia.australia", "globe.asia.australia.fill",
                "house", "house.fill", "house.circle", "house.circle.fill",
                "building", "building.fill", "building.2", "building.2.fill",
                "tray", "tray.fill", "tray.circle", "tray.circle.fill",
                "archivebox", "archivebox.fill", "archivebox.circle", "archivebox.circle.fill",
                "trash", "trash.fill", "trash.circle", "trash.circle.fill",
                "trash.slash", "trash.slash.fill",
                "cart", "cart.fill", "cart.circle", "cart.circle.fill",
                "bag", "bag.fill", "bag.circle", "bag.circle.fill",
                "gift", "gift.fill", "gift.circle", "gift.circle.fill",
                "camera", "camera.fill", "camera.circle", "camera.circle.fill",
                "camera.viewfinder", "viewfinder", "viewfinder.circle", "viewfinder.circle.fill",
                "creditcard", "creditcard.fill", "creditcard.circle", "creditcard.circle.fill",
                "clock", "clock.fill", "clock.circle", "clock.circle.fill",
                "clock.arrow.circlepath", "clock.badge", "clock.badge.fill",
                "calendar", "calendar.circle", "calendar.circle.fill",
                "calendar.badge.plus", "calendar.badge.minus", "calendar.badge.clock",
                "bookmark", "bookmark.fill", "bookmark.circle", "bookmark.circle.fill",
                "bookmark.slash", "bookmark.slash.fill",
                "binoculars", "binoculars.fill",
                "paperclip", "paperclip.circle", "paperclip.circle.fill",
                "link", "link.circle", "link.circle.fill", "link.badge.plus",
                "bandage", "bandage.fill", "cross", "cross.fill", "cross.circle", "cross.circle.fill",
                "stethoscope", "pills", "pills.fill", "syringe", "syringe.fill",
                "medical.thermometer", "medical.thermometer.fill",
                "trophy", "trophy.fill", "medal", "medal.fill",
                "crown", "crown.fill",
                "theatermask.and.paintbrush", "theatermask.and.paintbrush.fill",
            ]
        case .devices:
            return [
                "iphone", "iphone.circle", "iphone.circle.fill", "iphone.slash",
                "ipad", "ipad.landscape", "ipad.rear.camera",
                "applewatch", "applewatch.watchface",
                "macbook", "macbook.and.iphone",
                "tv", "tv.fill", "tv.circle", "tv.circle.fill",
                "tv.slash", "tv.badge.wifi", "tv.badge.wifi.fill",
                "airplay.video", "airplay.audio",
                "homepod", "homepod.fill", "homepod.mini", "homepod.mini.fill",
                "homepodmini.and.homepodmini", "hifispeaker", "hifispeaker.fill",
                "airpods", "airpodpro.right", "airpodpro.left",
                "airpods.gen3.right", "airpods.gen3.left",
                "earbuds", "headphones", "headphones.circle", "headphones.circle.fill",
                "keyboard", "keyboard.fill", "keyboard.slash",
                "mouse", "mouse.fill", "trackpad", "trackpad.fill",
                "computermouse", "computermouse.fill",
                "printer", "printer.fill", "printer.dotmatrix", "printer.dotmatrix.fill",
                "scanner",
                "cpu", "cpu.fill", "memorychip", "memorychip.fill",
                "sdcard", "sdcard.fill", "externaldrive", "externaldrive.fill",
                "internaldrive", "internaldrive.fill",
                "server.rack", "xserve",
                "battery.100", "battery.75", "battery.50", "battery.25",
                "battery.0", "battery.100.bolt", "battery.slash",
                "powerplug", "powerplug.fill", "power", "powersleep", "poweroff",
                "lightswitch.on", "lightswitch.on.fill", "lightswitch.off", "lightswitch.off.fill",
                "sensor", "sensor.fill", "gyroscope",
                "simcard", "simcard.fill", "simcard.2", "simcard.2.fill",
                "esim", "esim.fill",
            ]
        case .gaming:
            return [
                "gamecontroller", "gamecontroller.fill",
                "l.joystick", "r.joystick", "l.joystick.fill", "r.joystick.fill",
                "dpad", "dpad.fill", "dpad.up.fill", "dpad.down.fill", "dpad.left.fill", "dpad.right.fill",
                "circle.grid.cross", "circle.grid.cross.fill",
                "l.button.roundedbottom.horizontal", "r.button.roundedbottom.horizontal",
                "l1.button.roundedbottom.horizontal", "r1.button.roundedbottom.horizontal",
                "l2.button.roundedtop.horizontal", "r2.button.roundedtop.horizontal",
                "a.button.roundedtop.horizontal", "b.button.roundedtop.horizontal",
                "x.button.roundedtop.horizontal", "y.button.roundedtop.horizontal",
                "checkerboard.rectangle", "dice", "dice.fill",
                "suit.spade", "suit.spade.fill", "suit.heart", "suit.heart.fill",
                "suit.diamond", "suit.diamond.fill", "suit.club", "suit.club.fill",
                "puzzlepiece", "puzzlepiece.fill", "puzzlepiece.extension", "puzzlepiece.extension.fill",
                "chess.pawn", "chess.pawn.fill", "chess.king", "chess.king.fill",
                "flag.checkered", "flag.checkered.2.crossed",
                "trophy.fill", "medal.fill", "crown.fill",
                "figure.run", "figure.walk", "figure.badminton",
                "figure.basketball", "figure.soccer", "figure.tennis",
                "figure.golf", "figure.skiing.crosscountry", "figure.snowboarding",
                "figure.surfing", "figure.archery",
                "football", "basketball", "volleyball",
                "tennis.ball", "baseball", "soccerball",
            ]
        case .connectivity:
            return [
                "wifi", "wifi.slash", "wifi.circle", "wifi.circle.fill",
                "wifi.exclamationmark", "wifi.router", "wifi.router.fill",
                "antenna.radiowaves.left.and.right", "antenna.radiowaves.left.and.right.slash",
                "wave.3.left", "wave.3.left.circle", "wave.3.left.circle.fill",
                "wave.3.right", "wave.3.right.circle", "wave.3.right.circle.fill",
                "wave.3.forward", "wave.3.backward",
                "network", "network.slash", "network.badge.shield.half.filled",
                "globe.badge.chevron.backward",
                "dot.radiowaves.right",
                "dot.radiowaves.left.and.right",
                "bluetooth", "bluetooth.slash",
                "airplayaudio", "airplayvideo",
                "personalhotspot", "personalhotspot.circle", "personalhotspot.circle.fill",
                "cellularbars", "4g.alt",
                "5g.alt",
                "bolt.horizontal.circle", "bolt.horizontal.circle.fill",
                "cable.connector", "cable.connector.horizontal",
                "usb.dongle", "usb.dongle.fill",
                "point.topleft.down.to.point.bottomright.curvepath",
                "fibrechannel",
                "server.rack",
                "cloud", "cloud.fill", "icloud", "icloud.fill",
                "icloud.circle", "icloud.circle.fill",
                "icloud.slash", "icloud.slash.fill",
                "arrow.clockwise.icloud", "arrow.clockwise.icloud.fill",
                "arrow.counterclockwise.icloud", "arrow.counterclockwise.icloud.fill",
                "bolt.badge.clock", "bolt.badge.clock.fill",
                "shareplay", "airdrop",
                "lock.icloud", "lock.icloud.fill",
            ]
        case .transport:
            return [
                "car", "car.fill", "car.circle", "car.circle.fill",
                "car.front.waves.up", "car.front.waves.up.fill",
                "car.rear", "car.rear.fill",
                "car.side", "car.side.fill", "car.side.air.circulate",
                "car.top.door.front.left.open", "car.top.radiowaves.front",
                "suv.side", "suv.side.fill",
                "truck.box", "truck.box.fill", "truck.pickup.side", "truck.pickup.side.fill",
                "bicycle", "bicycle.circle", "bicycle.circle.fill",
                "scooter", "motorcycle",
                "bus", "bus.fill", "bus.doubledecker", "bus.doubledecker.fill",
                "tram", "tram.fill", "tram.circle", "tram.circle.fill",
                "tram.tunnel.fill",
                "ferry", "ferry.fill",
                "sailboat", "sailboat.fill",
                "airplane", "airplane.circle", "airplane.circle.fill",
                "airplane.departure", "airplane.arrival",
                "helicopter",
                "train.side.front.car", "train.side.rear.car",
                "fuelpump", "fuelpump.fill", "fuelpump.circle", "fuelpump.circle.fill",
                "steeringwheel", "steeringwheel.badge.exclamationmark",
                "road.lanes", "road.lanes.curved.left", "road.lanes.curved.right",
                "signpost.right", "signpost.right.fill", "signpost.left", "signpost.left.fill",
                "parkingsign", "parkingsign.circle", "parkingsign.circle.fill",
                "parkingsign.strikethrough",
                "map", "map.fill", "mappin", "mappin.circle", "mappin.circle.fill",
                "mappin.slash",
                "location", "location.fill", "location.circle", "location.circle.fill",
                "location.slash", "location.slash.fill",
                "location.north", "location.north.fill",
                "location.north.line", "location.north.line.fill",
                "compass.drawing", "arrow.triangle.turn.up.right.circle",
                "arrow.triangle.turn.up.right.circle.fill",
            ]
        case .human:
            return [
                "person", "person.fill", "person.circle", "person.circle.fill",
                "person.crop.circle", "person.crop.circle.fill",
                "person.crop.square", "person.crop.square.fill",
                "person.crop.rectangle", "person.crop.rectangle.fill",
                "person.badge.plus", "person.badge.minus",
                "person.badge.clock", "person.badge.clock.fill",
                "person.badge.shield.checkmark",
                "person.slash", "person.slash.fill",
                "person.2", "person.2.fill", "person.2.circle", "person.2.circle.fill",
                "person.2.slash", "person.2.slash.fill",
                "person.3", "person.3.fill", "person.3.slash", "person.3.slash.fill",
                "figure", "figure.stand", "figure.walk", "figure.run", "figure.roll",
                "figure.wave", "figure.wave.circle", "figure.wave.circle.fill",
                "figure.2", "figure.2.circle", "figure.2.circle.fill",
                "figure.2.and.child.holdinghands",
                "figure.and.child.holdinghands",
                "person.and.arrow.left.and.arrow.right",
                "person.and.background.dotted",
                "figure.seated.seatbelt",
                "figure.dress.line.vertical.figure",
                "hand.raised", "hand.raised.fill", "hand.raised.circle", "hand.raised.circle.fill",
                "hand.raised.slash", "hand.raised.slash.fill",
                "hand.raised.square", "hand.raised.square.fill",
                "hand.point.up", "hand.point.up.fill",
                "hand.point.down", "hand.point.down.fill",
                "hand.point.left", "hand.point.left.fill",
                "hand.point.right", "hand.point.right.fill",
                "hand.thumbsup", "hand.thumbsup.fill",
                "hand.thumbsdown", "hand.thumbsdown.fill",
                "hand.thumbsup.circle", "hand.thumbsup.circle.fill",
                "hand.thumbsdown.circle", "hand.thumbsdown.circle.fill",
                "hands.sparkles", "hands.sparkles.fill",
                "hand.tap", "hand.tap.fill",
                "hand.draw", "hand.draw.fill",
                "hands.clap", "hands.clap.fill",
                "face.smiling", "face.smiling.fill",
                "face.dashed", "face.dashed.fill",
                "eye", "eye.fill", "eye.circle", "eye.circle.fill",
                "eye.slash", "eye.slash.fill",
                "eye.trianglebadge.exclamationmark", "eye.trianglebadge.exclamationmark.fill",
                "nose", "nose.fill", "mouth", "mouth.fill",
                "ear", "ear.fill", "ear.badge.checkmark", "ear.trianglebadge.exclamationmark",
                "brain", "brain.fill", "brain.head.profile",
                "heart", "heart.fill", "heart.circle", "heart.circle.fill",
                "heart.slash", "heart.slash.fill",
                "heart.text.square", "heart.text.square.fill",
                "suit.heart", "suit.heart.fill",
                "lungs", "lungs.fill",
                "stethoscope", "bandage", "bandage.fill",
                "syringe", "syringe.fill",
                "figure.mind.and.body", "figure.cooldown", "figure.core.training",
                "figure.highintensity.intervaltraining", "figure.pilates", "figure.yoga",
                "figure.flexibility",
            ]
        case .nature:
            return [
                "leaf", "leaf.fill", "leaf.circle", "leaf.circle.fill",
                "leaf.arrow.circlepath",
                "tree", "tree.fill", "tree.circle", "tree.circle.fill",
                "plant", "carrot", "carrot.fill",
                "drop", "drop.fill", "drop.circle", "drop.circle.fill",
                "drop.degreesign", "drop.degreesign.fill",
                "humidity", "humidity.fill",
                "flame", "flame.fill", "flame.circle", "flame.circle.fill",
                "bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill",
                "bolt.slash", "bolt.slash.fill",
                "snowflake", "snowflake.circle", "snowflake.circle.fill",
                "wind", "wind.snow",
                "sun.max", "sun.max.fill", "moon", "moon.fill",
                "star", "star.fill", "star.circle", "star.circle.fill",
                "sparkle", "sparkles", "sparkle.magnifyingglass",
                "mountain.2", "mountain.2.fill",
                "globe", "globe.americas", "globe.americas.fill",
                "map", "map.fill",
                "pawprint", "pawprint.fill", "pawprint.circle", "pawprint.circle.fill",
                "tortoise", "tortoise.fill",
                "hare", "hare.fill",
                "ant", "ant.fill", "ant.circle", "ant.circle.fill",
                "ladybug", "ladybug.fill",
                "fish", "fish.fill",
                "bird", "bird.fill", "bird.circle", "bird.circle.fill",
                "lizard", "lizard.fill",
                "fossil.shell", "fossil.shell.fill",
                "tree.circle", "tree.circle.fill",
                "allergens", "allergens.fill",
                "aqi.low", "aqi.medium", "aqi.high",
                "seal", "seal.fill",
            ]
        case .editing:
            return [
                "pencil", "pencil.circle", "pencil.circle.fill", "pencil.slash",
                "pencil.and.outline", "pencil.tip",
                "pencil.tip.crop.circle", "pencil.tip.crop.circle.badge.plus",
                "pencil.tip.crop.circle.badge.minus",
                "eraser", "eraser.fill", "eraser.line.dashed", "eraser.line.dashed.fill",
                "square.and.pencil", "square.and.pencil.circle", "square.and.pencil.circle.fill",
                "rectangle.and.pencil.and.ellipsis",
                "scribble", "scribble.variable",
                "lasso", "lasso.badge.sparkles",
                "scissors", "scissors.circle", "scissors.circle.fill",
                "scissors.badge.ellipsis",
                "crop", "crop.rotate",
                "rotate.left", "rotate.left.fill", "rotate.right", "rotate.right.fill",
                "flip.horizontal", "flip.horizontal.fill",
                "skew", "perspective",
                "slider.horizontal.3", "slider.horizontal.below.rectangle",
                "slider.horizontal.below.square.and.square.filled",
                "slider.vertical.3",
                "dial.low", "dial.low.fill", "dial.high", "dial.high.fill",
                "wand.and.rays", "wand.and.rays.inverse",
                "wand.and.sparkles", "wand.and.sparkles.inverse",
                "wand.and.stars", "wand.and.stars.inverse",
                "magic.wand.and.hat.fill",
                "paintpalette", "paintpalette.fill",
                "eyedropper", "eyedropper.full",
                "eyedropper.halffull",
                "swatchpalette", "swatchpalette.fill",
                "swatch.palette", "swatch.palette.fill",
                "camera.filters",
                "selection.pin.in.out",
                "aspectratio", "aspectratio.fill",
                "arrow.up.and.down.and.sparkles",
                "sparkles.rectangle.stack", "sparkles.rectangle.stack.fill",
                "sparkles.square.filled.on.square",
                "sparkle.magnifyingglass",
            ]
        case .textFormatting:
            return [
                "textformat", "textformat.abc", "textformat.abc.dottedunderline",
                "textformat.size", "textformat.size.larger", "textformat.size.smaller",
                "textformat.alt",
                "bold", "bold.italic.underline",
                "italic", "underline", "strikethrough",
                "shadow", "bold.underline",
                "character", "character.cursor.ibeam", "character.magnify",
                "character.textbox", "character.phonetic",
                "a.magnify",
                "abc", "textformat.characters", "textformat.characters.dottedunderline",
                "text.alignleft", "text.alignright", "text.aligncenter", "text.justify",
                "text.justify.leading", "text.justify.trailing",
                "increase.indent", "decrease.indent",
                "increase.quotelevel", "decrease.quotelevel",
                "list.bullet", "list.bullet.circle", "list.bullet.circle.fill",
                "list.dash", "list.dash.header.rectangle",
                "list.number", "list.star",
                "list.triangle", "list.bullet.indent", "list.bullet.below.rectangle",
                "checklist", "checklist.checked", "checklist.unchecked",
                "paragraph", "function", "sum",
                "quote.opening", "quote.closing",
                "text.redaction", "text.word.spacing",
                "arrow.up.doc", "arrow.up.doc.fill",
                "arrow.down.doc", "arrow.down.doc.fill",
                "doc.text", "doc.text.fill", "doc.text.magnifyingglass",
                "doc.plaintext", "doc.richtext",
                "doc.append", "doc.append.fill",
                "doc.badge.plus", "doc.badge.gearshape",
                "newspaper", "newspaper.fill",
                "book.closed", "book.closed.fill",
                "magazines", "magazines.fill",
                "text.book.closed", "text.book.closed.fill",
            ]
        case .multicolor:
            return [
                "paintpalette", "paintpalette.fill",
                "swatchpalette", "swatchpalette.fill",
                "theatermasks", "theatermasks.fill",
                "theatermask.and.paintbrush", "theatermask.and.paintbrush.fill",
                "camera.aperture",
                "camera.filters",
                "photo.artframe",
                "photo.artframe.circle",
                "photo.fill.on.rectangle.fill",
                "photo.on.rectangle", "photo.on.rectangle.angled",
                "photo.stack", "photo.stack.fill",
                "photo", "photo.fill",
                "photo.circle", "photo.circle.fill",
                "rectangle.on.rectangle.angled",
                "sparkles",
                "wand.and.sparkles",
                "wand.and.stars",
                "flag.filled.and.flag.crossed",
                "flag.and.flag.filled.crossed",
                "trophy", "trophy.fill",
                "medal", "medal.fill",
                "crown", "crown.fill",
                "star.bubble", "star.bubble.fill",
                "questionmark.bubble", "questionmark.bubble.fill",
                "checkmark.bubble", "checkmark.bubble.fill",
                "exclamationmark.bubble", "exclamationmark.bubble.fill",
                "rainbow",
                "party.popper", "party.popper.fill",
                "balloon.2", "balloon.2.fill",
                "gift", "gift.fill",
                "birthday.cake", "birthday.cake.fill",
                "fireworks",
                "figure.walk.circle.fill",
                "beach.umbrella", "beach.umbrella.fill",
                "sofa", "sofa.fill",
                "fireplace", "fireplace.fill",
                "globe.americas.fill",
                "globe.europe.africa.fill",
                "globe.asia.australia.fill",
                "sun.and.horizon.fill",
            ]
        }
    }
}

// MARK: - Full Symbol List + Featured

enum SFSymbolLibrary {
    static let featured: [String] = [
        "star.fill", "heart.fill", "checkmark.circle.fill", "xmark.circle.fill",
        "bell.fill", "gear", "house.fill", "person.crop.circle.fill",
        "magnifyingglass", "arrow.clockwise", "iphone", "wand.and.sparkles",
        "bolt.fill", "leaf.fill", "camera.fill", "moon.stars.fill",
    ]

    // Loaded once from SFSymbols.txt in the app bundle.
    // To populate with the full 6,900-name SF Symbols 7 library, run on any Mac:
    //
    //   cat /System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/symbol_order.plist \
    //     | plutil -convert json -o - - \
    //     | python3 -c "import json,sys; print('\n'.join(json.load(sys.stdin)))" \
    //     > DesignerBuddy/SFSymbols.txt
    //
    // Then add SFSymbols.txt to the DesignerBuddy target in Xcode.
    // Falls back to the curated category lists if the file is missing.
    static let all: [String] = {
        guard
            let url = Bundle.main.url(forResource: "SFSymbols", withExtension: "txt"),
            let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            return SFSymbolCategory.allCases.flatMap { $0.symbolNames }
        }
        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }()
}
