import Config

config :kv, routing_table: [{?a..?z, node()}]

if config_env() == :prod do
  config :kv, :routing_table, [
    {?a..?m, :"foo@LAPTOP-3E2U4CJ4"},
    {?n..?z, :"bar@LAPTOP-3E2U4CJ4"}
  ]
end
