package kubernetes.admission

team_volume := {
	"op": "add",
	"path": "/spec/volumes/-",
	"value": {
		"name": "teams",
		"nfs": {
			"server": "its-dsmlp-fs01.ucsd.edu",
			"path": "/export/teams",
		},
	},
}

team_volume_mount := {
	"op": "add",
	"path": "/spec/containers/0/volumeMounts/-",
	"value": {
		"name": "teams",
		"mountPath": concat("/", [get_homepath(username), "teams"]),
	},
}

patch[p] {
	team_gid
	p := replace_protect_patches([
		team_volume,
		team_volume_mount,
	])
}

######################### TESTS #########################

test_all_patches_added_when_uid_gid_specified {
	patch[[
		team_volume,
		team_volume_mount,
	]] with input.request as {"object": {
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
