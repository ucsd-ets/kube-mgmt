package kubernetes.admission

security_context_uid_replace_patch := {
	"op": "replace",
	"path": "/spec/securityContext",
	"value": {"runAsUser": fetch_uid(username)},
}

security_context_uid_add_patch := {
	"op": "add",
	"path": "/spec/securityContext",
	"value": {"runAsUser": fetch_uid(username)},
}

team_security_context_uid_gid_add := {
	"op": "add",
	"path": "/spec/securityContext",
	"value": {
		"runAsUser": fetch_uid(username),
		"fsGroup": to_number(team_gid),
		"runAsGroup": to_number(team_gid),
	},
}

team_security_context_uid_gid_replace_patch := {
	"op": "replace",
	"path": "/spec/securityContext",
	"value": {
		"runAsUser": fetch_uid(username),
		"fsGroup": to_number(team_gid),
		"runAsGroup": to_number(team_gid),
	},
}

patch[p] {
	not team_gid
	p := replace_protect_patches([security_context_uid_add_patch])
}

patch[p] {
	team_gid
	p := replace_protect_patches([team_security_context_uid_gid_add])
}

######################### TESTS #########################

test_all_patches_added_when_uid_not_specified {
	patch[[security_context_uid_add_patch]] with input.request as {"object": {
		"metadata": {
			"labels": {"dsmlp/user": "dhub19"},
			"namespace": "dhub19",
		},
		"spec": {"containers": {
			"name": "test",
			"image": "fakeimg:faketag",
		}},
	}}
}

test_all_patches_replaced_when_uid_gid_specified {
	patch[[security_context_uid_replace_patch]] with input.request as {"object": {
		"metadata": {
			"labels": {"dsmlp/user": "dhub19"},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": [{
				"name": "test",
				"image": "fakeimg:faketag",
			}],
			"securityContext": {"runAsUser": 1000},
		},
	}}
}

test_all_patches_added_when_uid_gid_specified {
	patch[[team_security_context_uid_gid_add]] with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/user": "dhub19",
				"dsmlp/team": "10000",
			},
			"namespace": "dhub19",
		},
		"spec": {"containers": {
			"name": "test",
			"image": "fakeimg:faketag",
		}},
	}}
}

test_all_patches_replaced_when_uid_gid_specified {
	patch[[team_security_context_uid_gid_replace_patch]] with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/user": "dhub19",
				"dsmlp/team": "10000",
			},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": [{
				"name": "test",
				"image": "fakeimg:faketag",
			}],
			"securityContext": {
				"runAsUser": 1000,
				"runAsGroup": 100,
			},
		},
	}}
}
