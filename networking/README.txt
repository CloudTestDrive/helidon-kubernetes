This assumes that you have created a cluster with calico enabled 
export DEFAULT_CLUSTER_CONTEXT_NAME=calico 
and then run a script resulting in a cluster will do this for you
You also need to have configured and installed the logger (this is needed to enable the data separation)
the persistence/logger-microservice-setup.sh script does this one

These policies are applied to the default namespace

The YAML files here set up the networking.
Note that this WILL NOT restrict  zipkin - that is allowed to accept data from everywhere

