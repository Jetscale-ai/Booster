package main

import "testing"

func TestGreet(t *testing.T) {
	got := Greet("Booster")
	want := "Hello, Booster!"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

