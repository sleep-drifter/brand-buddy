package com.designerbuddy.core.catalog

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FuzzyMatchTest {

    @Test
    fun `empty query matches anything`() {
        assertTrue(fuzzyMatch("", "buttons"))
        assertTrue(fuzzyMatch("", ""))
    }

    @Test
    fun `exact match`() {
        assertTrue(fuzzyMatch("buttons", "buttons"))
    }

    @Test
    fun `in-order subsequence matches`() {
        assertTrue(fuzzyMatch("btn", "buttons"))
        assertTrue(fuzzyMatch("txtfld", "text fields"))
    }

    @Test
    fun `out-of-order does not match`() {
        assertFalse(fuzzyMatch("snottub", "buttons"))
    }

    @Test
    fun `query longer than target does not match`() {
        assertFalse(fuzzyMatch("buttonsss", "buttons"))
    }
}
