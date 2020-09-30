Logger.configure(level: :info)

# Multi node testing
# :os.cmd('epmd -daemon')
Ratelab.Cluster.spawn([:"node1@127.0.0.1", :"node2@127.0.0.1"])
ExUnit.start()
