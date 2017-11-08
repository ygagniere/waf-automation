#!/usr/bin/ruby

require "net/http"
require "uri"
require "json"
require "base64"

sleep 300
###Querying AWS for the the Instance ID and the Public and Private IP###
class Waf_Info
		instance_id = `aws ec2 describe-instances --filter Name=tag:Name,Values=awswafinstancebyPUPPET7 --query 'Reservations[*].Instances[*].[InstanceId]' --output text`
		@@ins_id = "#{instance_id.chomp}"
	        eip_alloc_json = `aws ec2 describe-addresses --filters "Name=domain,Values=vpc"`
                eip_alloc_json_parsed = JSON.parse(eip_alloc_json)
		eip_alloc_json_parsed ['Addresses'].each do |info|
		eip_alloc_id = info ['AllocationId']
		attach_ip = `aws ec2 associate-address --instance-id "#{instance_id.chomp}" --allocation-id "#{eip_alloc_id.chomp}"`
		@@att_ip = "#{attach_ip.chomp}"
		end
		public_ip = `aws ec2 describe-instances --filter Name=tag:Name,Values=awswafinstancebyPUPPET7 --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
		@@pub_ip = "#{public_ip.chomp}"

		system_ip = `aws ec2 describe-instances --filter Name=tag:Name,Values=awswafinstancebyPUPPET7 --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text`
		@@sys_ip = "#{system_ip.chomp}"

		common = "#{public_ip.chomp}:8000/restapi/v1/"
		@@common_url = "#{common}"

		header = "-X POST -H Content-Type:application/json -d"
		@@http_header = "#{header}"

		common_service_path = "#{common}virtual_services"
		@@service_url = "#{common_service_path}"

		svr_system_ip = `aws ec2 describe-instances --filter Name=tag:Name,Values=lampinstancebyPUPPET7 --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text`
		@@svr_sys_ip = "#{svr_system_ip.chomp}"

	def self.ins_id
	@@ins_id
	end
	def ins_id
	@@ins_id
	end
	def self.att_ip
        @@att_ip
        end
        def att_ip
        @@att_ip
        end
	def self.pub_ip
	@@pub_ip
	end
	def pub_ip
	@@pub_ip
	end
	def self.sys_ip
	@@sys_ip
	end
	def sys_ip
	@@sys_ip
	end
	def self.common_url
	@@common_url
	end
	def common_url
	@@common_url
	end
	def self.http_header
	@@http_header
	end
	def http_header
	@@http_header
	end
	def self.service_url
	@@service_url
	end
	def service_url
	@@service_url
	end
	def self.svr_sys_ip
	@@svr_sys_ip
	end
	def svr_sys_ip
	@@svr_sys_ip
	end
end

#accepting EULA
class EULA < Waf_Info
		
	def agreement
	instance_id_waf = Waf_Info.ins_id
	instance_publicip = Waf_Info.pub_ip
	instance_sysip = Waf_Info.sys_ip
	common_urlpath = Waf_Info.common_url
	header_http = Waf_Info.http_header
	serviceurl = Waf_Info.service_url
	puts "The system's instance ID is #{instance_id_waf}"
	puts "The systems's public IP is #{instance_publicip}"
	puts "The system ip of the instance is #{instance_sysip}"
	#Accepting EULA
	eula_output = 0
	until eula_output == "200"
	
	eula_uri = URI.parse("http://#{instance_publicip}:8000/")
	eula_http = Net::HTTP.new(eula_uri.host, eula_uri.port)
	eula_request = Net::HTTP::Get.new(eula_uri.path)
	eula_response = eula_http.request(eula_request)
	eula_output = eula_response.code
	end
	
	accept_params = "name_sign=self-provisioned&email_sign=self-provisioned&company_sign=self-provisioned&eula_hash_val=ed4480205f84cde3e6bdce0c987348d1d90de9db&action=save_signed_eula"
		eula_post = Net::HTTP::Post.new(eula_uri.path)
		eula_post.body = "{#{accept_params}}"
		eula_http.request(eula_post)
		puts "waiting till the WAF is provisioned"
		sleep 30
	end
end

eula = EULA.new
eula.agreement


#Logging in to the WAF :###
class Token < Waf_Info
		def logintoken
		
		
        	instance_publicip = Waf_Info.pub_ip
        	login_check = URI.parse("http://#{instance_publicip}:8000/cgi-bin/index.cgi")
		login_check_http = Net::HTTP.new(login_check.host, 8000)
		login_request = Net::HTTP::Get.new(login_check.path)
		response_check = login_check_http.request(login_request)
		urlpath = Waf_Info.common_url
		uri = URI.parse("http://#{urlpath}login")
		password = Waf_Info.ins_id
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
		request.body = {"username" => "admin", "password" => "#{password}"}.to_json
		response = http.request(request)
		output = response.body
		parsed_json = JSON.parse(output)
		token_value = parsed_json ["token"]
		@@token = token_value.chomp
		#puts "#{token_value.chomp}"
		end
	def self.token
	@@token
	end
	def token
	@@token
	end
end
token_for_login = Token.new
token_for_login.logintoken



#HTTP Service
	class WAF_CONFIG < Waf_Info::Token
		def config

#Services details
http_svc_name = "service_http_auto"

#website details
	http_fqdn = "staging.selahcloud.in"

#waf details
	wafip = Waf_Info.sys_ip
	wafport = 8000
	waftoken = Token.token
	common_path = Waf_Info.common_url
	header_string = Waf_Info.http_header
	common_path_service = Waf_Info.service_url
	server_ip = Waf_Info.svr_sys_ip
#System Serial
		serial_number_response = `curl http://#{common_path}/system -u '#{waftoken}:'`
		serial_json = JSON.parse (serial_number_response)
		serial_number = serial_json ["system_serial"]
		
#PRODUCION
#Service creation
puts "Creating the configuration for the production service group"
puts "=========================================================== \n"
		svc = `curl http://#{common_path_service} -u '#{waftoken}:' #{header_string} '{"name": "#{http_svc_name}", "ip_address":"#{wafip}", "port":"80", "type":"HTTP", "address_version":"ipv4", "vsite":"default", "group":"default"}'`
server_create = `curl http://#{common_path_service}/#{http_svc_name}/servers -u '#{waftoken}' #{header_string} '{"address_version":"ipv4","name":"S1","ip_address":"#{server_ip}","port":80}'`

#Connecting the unit to BCC
bcc = `cat /etc/puppetlabs/puppet/bcc_credentials`
bcc_json = JSON.parse (bcc)
bcc_user = bcc_json ["username"]
bcc_password = bcc_json ["password"]
bcc_link = `curl http://#{common_path}cloud_control -u '#{waftoken}:' -X PUT -H Content-Type:application/json -d '{"connect_mode":"cloud","state":"connected","username":"#{bcc_user}","password":"#{bcc_password}","barracuda_control_server":"svc.bcc.barracudanetworks.com"}'`
#puts "#{bcc_link}"
puts "=================================================================== \n\n"
puts "This unit is now linked to the Barracuda Cloud Control Service as well as the Barracuda Vulnerability Remediation Service"
	end
end

config_waf = WAF_CONFIG.new
config_waf.config

