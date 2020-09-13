# l4d2-server
# What is this?

It's a project to deploy a server for playing L4D2 with your friends. It is stressful, exciting, and fun.

# Why is this?

Because I saw that scene in World War Z with the hordes of zombies and wanted to play a game around it.

# How is this?

The project leverages Terraform and Docker to spin up a server in less than five minutes. To make this work, you'll need the following things:

- A basic understanding of git (how to pull, add and commit)
- A basic understanding of docker (how to add, build and push images)
- Git, Docker, and Terraform installed on your computer
- The google cloud sdk installed on your computer, linked to a account with a credit card
- A copy of Left 4 Dead 2

# Make it so

From the google cloud console, create a project. Note whatever the project id is, you'll need it

Under that project, create a bucket, name it "l4d2".

Clone this respository.

You'll need to update the following parts of the "main.tf" file.

- If you named your bucket "l4d2", skip this. Otherwise, update 

terraform {
  backend "gcs" {
    prefix = "l4d2/state"
    bucket = "l4d2"
  }
}

with your new bucket name

- Update the following portion with whatever region you want to use for your server. Local is better.

locals {
  \# The Google Cloud Project ID that will host and pay for your l4d2 server
  project = "###PROJECT ID HERE###"
  region  = "us-west2"
  zone    = "us-west2-a"
  
- You can change the instance type, if you don't have super hordes or want to save some pennies. The n1 series are fine for standard games.

resource "google_compute_instance" "l4d2" {
  name         = "l4d2"
  machine_type = "c2-standard-4"
  zone         = local.zone
  tags         = ["l4d2"]
  
- If you're making your own docker images, you'll need to update this line:

  metadata_startup_script = "docker run -p 27015:27015 -p 27015:27015/udp -p 27020:27020/udp -m 14G --name l4d2-server mcpdude/l4d2server"
  
  to wherever you're hosting your images. 
  
  Credit goes to Snipzwolf, who made the original docker image I'm cribbing off, and Tom Larkworthy for the Minecraft terraform script I'm using.
  
Now that you've got a terraform script setup, we can change some aspects of the docker image to better suit you.

If you just want to start playing, you can `cd` into the repository directory, then run `terraform init`. Follow this with `terraform apply`, enter yes when prompted, and wait five minutes. If you look under the Compute instances in your Google Cloud console, you'll see a l4d2 instance with a IP. Copy the IP, then in Left 4 Dead 2, open the console* (~), type `connect <the copied IP>` and hit enter. You'll connect to your new server. Send the IP to friends to let them in; matchmaking is disabled to avoid randos joining.

If you want to make changes (Please do!), read on.

The primary files to change are server.cfg and the Dockerfile.

With the server.cfg, you can alter cvars, which change how the server operates. There are a shit ton of cvars, and they are not well documented, so change with caution. 

With the Dockerfile, you can define which files are added to the server, and thus, you can add mods to the server. Currently, MetaMod and SourceMod are included by default, so adding mods is as simple as following instructions on alliedmodders.net.


