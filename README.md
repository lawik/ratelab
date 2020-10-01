# Ratelab

Experiment on rate limiting outbound requests (and eventually requests/time) via Poolboy and some single global processes over a cluster.

Trade-offs are focused on avoiding eventual consistency and making sure it doesn't violate rate constraints during normal operation. If a node dies the next request will have a certain risk of violating the constraints as we lose the state but it will recover and build back up.

It also has an example of cross-node testing which is mostly taken from the Phoenix PubSub repo. That's a finicky thing. Be aware that any "anonymous" function you send needs to be in a compiled module (in this case NodeCase) so that the remote node that tries to execute it actually has the relevant module. The RatelabTest module is not compiled and using NodeCase.call_node style calls directly from it will give undefined function errors.
