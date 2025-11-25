//go:build mage
// +build mage

package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// LocalRelease simulates the release workflow locally using 'gh act'.
// It requires a .secrets file with DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, and GITHUB_TOKEN.
func LocalRelease() error {
	mg.Deps(CheckGhInstalled)

	fmt.Println("Running release workflow locally with gh act...")
	fmt.Println("Ensure you have a .secrets file with DOCKERHUB_USERNAME and DOCKERHUB_TOKEN if needed.")

	if _, err := os.Stat(".secrets"); os.IsNotExist(err) {
		fmt.Println("Warning: .secrets file not found. Credentials might be missing for the local run.")
	}

	// We use sh.RunV to stream output to stdout
	// Using 'gh act' instead of 'act' directly
	return sh.RunV("gh", "act", "push", "-j", "release", "--secret-file", ".secrets")
}

// CheckGhInstalled checks if 'gh' is installed and available in PATH.
func CheckGhInstalled() error {
	_, err := exec.LookPath("gh")
	if err != nil {
		return fmt.Errorf("gh is not installed. Please install it first (e.g. brew install gh)")
	}
	return nil
}

// Clean removes any temporary files or build artifacts
func Clean() {
	fmt.Println("Cleaning...")
	os.RemoveAll("version.txt")
}
