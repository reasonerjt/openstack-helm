[DEFAULT]
log-config-append = /etc/ironic/logging.conf
pybasedir = /ironic/ironic
network_provider = neutron_plugin
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

[agent]
deploy_logs_collect = {{ .Values.agent.deploy_logs.collect }}
deploy_logs_storage_backend = {{ .Values.agent.deploy_logs.storage_backend }}
deploy_logs_swift_days_to_expire = {{ .Values.agent.deploy_logs.swift_days_to_expire }}
{{- if eq .Values.agent.deploy_logs.storage_backend "swift" }}
deploy_logs_swift_project_name = {{ .Values.agent.deploy_logs.swift_project_name | required "Need a project name" }}
deploy_logs_swift_project_domain_name = {{ .Values.agent.deploy_logs.swift_project_domain_name | required "Need a domain name for the project" }}
deploy_logs_swift_container = {{ .Values.agent.deploy_logs.swift_container | default "ironic_deploy_logs_container" }}
{{- end }}

{{- if .Values.image_version_ironic_inspector }}

[inspector]
enabled=True
auth_section = keystone_authtoken
service_url=https://{{include "ironic_inspector_endpoint_host_public" .}}
{{- end }}

[dhcp]
dhcp_provider=neutron

[api]
host_ip = 0.0.0.0

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_plugin = v3password
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
username = {{ .Values.global.ironic_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.ironic_service_password | default (tuple . .Values.global.ironic_service_user | include "identity.password_for_user")  | replace "$" "$$" | quote }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}

[service_catalog]
auth_section = keystone_authtoken
insecure = True

[glance]
auth_section = keystone_authtoken
glance_host = {{.Values.global.glance_api_endpoint_protocol_internal}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal}}
swift_temp_url_duration=1200
# No terminal slash, it will break the url signing scheme
swift_endpoint_url={{.Values.global.swift_endpoint_protocol}}://{{include "swift_endpoint_host" .}}:{{ .Values.global.swift_api_port_public }}
swift_api_version=v1
{{- if .Values.swift_store_multi_tenant }}
swift_store_multi_tenant = True
{{- else}}
    {{- if .Values.swift_multi_tenant }}
swift_store_multiple_containers_seed=32
    {{- end }}
swift_temp_url_key={{ .Values.swift_tempurl }}
swift_account={{ .Values.swift_account }}
{{- end }}

[swift]
auth_section = keystone_authtoken
{{- if .Values.swift_set_temp_url_key }}
swift_set_temp_url_key = True
{{- end }}

[neutron]
auth_section = keystone_authtoken
url = {{.Values.global.neutron_api_endpoint_protocol_internal}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal }}
cleaning_network_uuid={{ .Values.network_cleaning_uuid }}
provisioning_network_uuid={{ .Values.network_management_uuid }}

{{include "oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = True

{{- include "osprofiler" . }}
