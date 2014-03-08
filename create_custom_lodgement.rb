#!/usr/bin/env ruby

require 'rubygems'
require 'right_api_client'
require '/var/spool/cloud/user-data.rb'

client = RightApi::Client.new(:instance_token => ENV['RS_RN_AUTH'], :account_id => ENV['RS_ACCOUNT'])
puts client.last_request[:request].url

instance = client.get_instance()
puts client.last_request[:request].url
instance_href = instance.href

lodgement_res = RightApi::Resources.new(client, "#{instance_href}/instance_custom_lodgements", "instance_custom_lodgements")

time = Time.now
timeframe = time.strftime("%Y_%m_%d")

lodgements = lodgement_res.index(:timeframe => timeframe)

value = `find /var/lib/collectd -name *.rrd | wc -l`

qty = [{:name => "monitoring_metrics", :value => value}]
if lodgements.size == 0
  lodgement_res.create(:quantity => qty, :timeframe => timeframe)
else
  lodgements_href = lodgements[0].href
  lodgement = client.resource(lodgements_href)
  lodgement.update(:quantity => qty)
end

puts lodgements[0].raw