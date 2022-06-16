package kubernetes.admission

toleration := {
	"op": "add",
	"path": "/spec/tolerations/-",
	"value": {
		"key": "node-type",
		"operator": "Equal",
		"value": "research",
	},
}

affinity := {
	"op": "add",
	"path": "/spec/affinity",
	"value": {"nodeAffinity": {"preferredDuringSchedulingIgnoredDuringExecution": [{
		"weight": 1,
		"preference": {"matchExpressions": [{
			"key": "node-type",
			"operator": "In",
			"values": ["research"],
		}]},
	}]}},
}

patch[p] {
	# For pods
	researcher
	p := [toleration]
}

patch[p] {
	# For pods
	# in other words, research annotation and at least 1 container specifies a GPU
	researcher
	input.request.object.spec.containers[_].resources.limits["nvidia.com/gpu"]
	p := [affinity]
}

######################### TESTS #########################

test_toleration_is_appended {
	patch[[toleration]] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {"dsmlp/research": "true"},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}

test_toleration_not_appended {
	not patch[[toleration]] with input.request as {"object": {
		"metadata": {"namespace": "dhub19"},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}

test_affinity_appended {
	patch[[affinity]] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {"dsmlp/research": "true"},
		},
		"spec": {
			"securityContext": {"runAsUser": 81172},
			"containers": [
				{"resources": {"limits": {"cpu": 1}}},
				{"resources": {"limits": {"nvidia.com/gpu": "1"}}},
			],
		},
	}}
}

test_affinity_not_appended {
	not patch[[affinity]] with input.request as {"object": {
		"metadata": {
			"namespace": "dhub19",
			"labels": {"dsmlp/research": "true"},
		},
		"spec": {
			"securityContext": {"runAsUser": 81172},
			"containers": [{"limits": {"cpu": 1}}],
		},
	}}
}
