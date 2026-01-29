// Package main provides the Booster CLI entry point.
package main

import "fmt"

func main() {
	fmt.Println(Greet("Booster"))
}

// Greet returns a greeting message for the given name.
func Greet(name string) string {
	return fmt.Sprintf("Hello, %s!", name)
}
