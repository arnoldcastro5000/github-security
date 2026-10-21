package main_test

import data.main

test_public_bucket_denied if {
	count(main.deny) == 1 with input as {"bucket": {"name": "logs", "public": true}}
}

test_private_bucket_allowed if {
	count(main.deny) == 0 with input as {"bucket": {"name": "logs", "public": false}}
}
