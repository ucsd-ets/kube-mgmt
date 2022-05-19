package kubernetes.admission

######################### TESTS #########################

test_deny_if_not_enrolled_in_any_courses {
	deny["dhub19 is not registered for COGS101_SP20_A00!"] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {
				"dsmlp/course": "COGS101_SP20_A00",
				"dsmlp/user": "dhub19",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
		 with enrollments as []
}

test_deny_if_not_enrolled_in_another_course {
	deny["dta001 is not registered for DSC170_WI20_A00!"] with input.request as {"object": {
		"metadata": {
			"namespace": "dta001",
			"labels": {
				"dsmlp/course": "DSC170_WI20_A00",
				"dsmlp/user": "dta001",
			},
		},
		"spec": {"securityContext": {"runAsUser": 68744}},
	}}
		 with enrollments as ["another"]
}

test_not_deny_if_enrolled {
	not deny["dhub19 is not registered for fa-jupyter!"] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {
				"dsmlp/course": "fa-jupyter",
				"dsmlp/user": "dhub19",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
		 with enrollments as ["fa-jupyter"]
}
