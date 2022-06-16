package kubernetes.admission

# if we're using umbrellas, add user's course umbrella home volume
# use_umbrellas
# p := [umbrella_volume(username, course, coursejson.fileSystem.server, coursejson.fileSystem.path)]

# patch[[home_env_var("/home/dhub19")]]
# umbrella-home -> /home/username
# home -> /home/username/private
test_use_umbrella_if_course_has_file_system {
	actual_patches := patch with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/course": "CSE101",
				"dsmlp/user": "dhub19",
			},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
		 with coursejson as {"fileSystem": {
			"identifier": "dev-umbrellas",
			"server": "its-dsmlpdev-fs01.ucsd.edu",
			"path": "/export/umbrellas",
		}}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	actual_patches[[nbgrader_umbrella_exchange_volume_mount_patch("CSE101")]]
	actual_patches[[nbgrader_umbrella_config_volume_mount_patch]]
	actual_patches[[nbgrader_env_patch2("CSE101")]]
	actual_patches[[home_env_var("/home/dhub19")]]

	not actual_patches[[nbgrader_volume_patch]]
	not actual_patches[[nbgrader_volume_mount_patch2("CSE101")]]
	not actual_patches[[nbgrader_config_volume_mount_patch2("CSE101")]]
	not actual_patches[[nbgrader_grader_volume_mount2("CSE101")]]
	not actual_patches[[nbgrader_grader_volume_mount_patch("CSE101")]]
}

test_umbrella_grader {
	actual_patches := patch with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/course": "CSE101",
				"dsmlp/user": "dhub19",
			},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
		 with coursejson as {
			"grader": {"username": "dhub19"},
			"fileSystem": {
				"identifier": "dev-umbrellas",
				"server": "its-dsmlpdev-fs01.ucsd.edu",
				"path": "/export/umbrellas",
			},
		}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	actual_patches[[nbgrader_umbrella_exchange_volume_mount_patch("CSE101")]]
	actual_patches[[nbgrader_umbrella_config_volume_mount_patch]]
	actual_patches[[nbgrader_env_patch2("CSE101")]]
	actual_patches[[home_env_var("/home/dhub19")]]

	not actual_patches[[nbgrader_volume_patch]]
	not actual_patches[[nbgrader_volume_mount_patch2("CSE101")]]
	not actual_patches[[nbgrader_config_volume_mount_patch2("CSE101")]]
	not actual_patches[[nbgrader_grader_volume_mount2("CSE101")]]
	not actual_patches[[nbgrader_grader_volume_mount_patch("CSE101")]]
}

test_use_legacy_nbgrader_if_course_has_no_filesystem {
	actual_patches := patch with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/course": "CSE101",
				"dsmlp/user": "dhub19",
			},
			"namespace": "dhub19",
		},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
		 with coursejson as {"grader": {"username": "bob"}}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	actual_patches[[nbgrader_volume_patch]]
	actual_patches[[nbgrader_volume_mount_patch2("CSE101")]]
	actual_patches[[nbgrader_env_patch2("CSE101")]]
	actual_patches[[nbgrader_config_volume_mount_patch2("CSE101")]]
	actual_patches[[nbgrader_grader_volume_mount2("CSE101")]]
	actual_patches[[home_env_var("/home/dhub19")]]

	not actual_patches[[nbgrader_umbrella_exchange_volume_mount_patch("CSE101")]]
	not actual_patches[[nbgrader_umbrella_config_volume_mount_patch]]
	not actual_patches[[nbgrader_grader_volume_mount_patch("CSE101")]]
}

test_mount_legacy_grader_home {
	actual_patches := patch with input.request as {"object": {
		"metadata": {
			"labels": {
				"dsmlp/course": "CSE101",
				"dsmlp/user": "bob",
			},
			"namespace": "bob",
		},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
		 with coursejson as {"grader": {"username": "bob"}}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	actual_patches[[nbgrader_grader_volume_mount_patch("CSE101")]]
	actual_patches[[home_env_var("/srv/nbgrader/CSE101")]]
}
