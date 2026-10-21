# METADATA
# description: Deny a public storage bucket.
package main

# METADATA
# entrypoint: true
deny contains msg if {
	input.bucket.public == true
	msg := sprintf("bucket %s must not be public", [input.bucket.name])
}
