package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {

    @Test
    void testAdd() {
        assertEquals(5, App.add(2, 3));
        assertEquals(0, App.add(-2, 2));
    }

    @Test
    void testMultiply() {
        assertEquals(6, App.multiply(2, 3));
        assertEquals(0, App.multiply(5, 0));
    }

    @Test
    void testIsPositive() {
        assertTrue(App.isPositive(5));
        assertFalse(App.isPositive(-1));
        assertFalse(App.isPositive(0));
    }
}
