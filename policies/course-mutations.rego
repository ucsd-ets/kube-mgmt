package kubernetes.admission

research_anti_affinity := {
	"op": "add",
	"path": "/spec/affinity",
	"value": {"nodeAffinity": {"preferredDuringSchedulingIgnoredDuringExecution": [{
		"weight": 10,
		"preference": {"matchExpressions": [{
			"key": "node-type",
			"operator": "NotIn",
			"values": ["research"],
		}]},
	}]}},
}

patch[p] {
	course
	p := [research_anti_affinity]
}

######################### TESTS #########################

test_toleration_is_appended {
	patch[[research_anti_affinity]] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {"dsmlp/course": "COGS101_SP20_A00"},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}
