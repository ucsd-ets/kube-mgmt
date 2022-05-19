package kubernetes.admission

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

	actual_patches[[umbrella_volume("dhub19", "CSE101", "its-dsmlpdev-fs01.ucsd.edu", "/export/umbrellas")]]
	actual_patches[[umbrella_volume_mount("dhub19")]]
	actual_patches[[home_volume]]
	actual_patches[[private_home_volume_mount("dhub19")]]
	actual_patches[[home_env_var("/home/dhub19")]]

	not actual_patches[[home_volume_mount("dhub19")]]
}

test_dont_use_umbrella_if_course_has_no_file_system {
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
		 with coursejson as {}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	actual_patches[[home_volume]]
	actual_patches[[home_volume_mount("dhub19")]]
	actual_patches[[home_env_var("/home/dhub19")]]

	not actual_patches[[umbrella_volume("dhub19", "CSE101", "its-dsmlpdev-fs01.ucsd.edu", "/export/umbrellas")]]
	not actual_patches[[umbrella_volume_mount("dhub19")]]
	not actual_patches[[private_home_volume_mount("dhub19")]]
}

test_dont_mount_any_volumes_if_no_dsmlp_labels_specified {
	actual_patches := patch with input.request as {"object": {
		"metadata": {"namespace": "dhub19"},
		"spec": {
			"containers": {
				"name": "test",
				"image": "fakeimg:faketag",
			},
			"securityContext": {"runAsUser": 81172},
		},
	}}
		 with data.coursejson as {}

	trace(sprintf("actual_patches=%v", [actual_patches]))

	not actual_patches[[private_home_volume_mount("dhub19")]]

	not actual_patches[[home_volume]]
	not actual_patches[[home_volume_mount("dhub19")]]

	not actual_patches[[umbrella_volume("dhub19", "CSE101", "its-dsmlpdev-fs01.ucsd.edu", "/export/umbrellas")]]
	not actual_patches[[umbrella_volume_mount("dhub19")]]
}

test_umbrella_volume_mount_patch {
	umbrella_volume_mount("dhub19") == {
		"op": "add",
		"path": "/spec/containers/0/volumeMounts/-",
		"value": {
			"name": "course-umbrella",
			"mountPath": "/home/dhub19",
			"subPath": "home/dhub19",
		},
	}
}

test_umbrella_volume_patch {
	actual_patch := umbrella_volume("dhub19", "CSE101", "its-dsmlpdev-fs01.ucsd.edu", "/export/umbrellas")
	trace(sprintf("actual_patch=%v", [actual_patch]))
	actual_patch == {
		"op": "add",
		"path": "/spec/volumes/-",
		"value": {
			"name": "course-umbrella",
			"nfs": {
				"server": "its-dsmlpdev-fs01.ucsd.edu",
				"path": "/export/umbrellas/CSE101",
			},
		},
	}
}
