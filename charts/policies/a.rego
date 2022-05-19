package kubernetes.admission

# annotation definitions live here. File called a.rego instead of
# annotations.rego due to a some issue with OPA when installing a file
# called annotations.rego (OPA will have a hard time loading in that file
# if you look through the logs)

# Also note that this file MUST be installed first, otherwise, OPA
# will not understand that annotations exist for files installed
# before it (weird part of it is that functions defined in util.rego work ok when installed
# in any order)

datahub := input.request.object.metadata.labels["dsmlp/datahub"]

researcher := input.request.object.metadata.labels["dsmlp/research"]

course := input.request.object.metadata.labels["dsmlp/course"]

username := input.request.object.metadata.labels["dsmlp/user"]

team_gid := input.request.object.metadata.labels["dsmlp/team"]

resource_type := input.request.object.metadata.labels["dsmlp/resource-type"]

preferenced_nodes := input.request.object.metadata.labels["dsmlp/node"]

auto_config {
	username
}
