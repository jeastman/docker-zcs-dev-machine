# Overview

This provides a container with ZCS + SOLR installed and configured for development work.

## Installing Docker

Please see the file `README_Docker_Install.md` for help with Docker installation
for Mac OS X or Linux. For help installing Docker for Windows, please see
[this document](https://drive.google.com/open?id=1ZGTekeAZhgwpApiPlwzvLj3kzR4prp0oCNNTXYuhg0w).

## Container Installation

Clone the dev machine docker image (this repo):

    git clone https://github.com/Zimbra/docker-zcs-dev-machine.git
    
Check out the version you want to work with, e.g. for "feature/solr" branch:

    git checkout -b feature/solr origin/feature/solr

## Additional Configuration

Copy the file `DOT-env` to `.env`.  Edit the file `.env` and replace the values
assigned to `GITEMAIL` and `GITNAME` with the email address you use for GitHub
and your actual first and last name. This information is used to initialize the
`.gitconfig` file that is installed into `/opt/zimbra`. This file is in the
`.gitignore` file so you don't accidentally commit changes to it.


_NOTE_: If you are using [docker-machine](https://docs.docker.com/machine/get-started/) with [VirtualBox](https://www.virtualbox.org/wiki/VirtualBox), you will have to go into the _Network_ preferences for the `default` VM in _Virtualbox Manager_ and add a port forwarding rule.

The setting for `HOME_ZIMBRA` should be the path to the directory you wish
to mount into your running `zcs-dev` container at `/home/zimbra`.  The
example value shown in `DOT-env` points to the `home-zimbra` directory that
is part of this repository.  Here are a couple of examples for the `HOME_ZIMBRA` 
envitonment variable setting:

- `HOME_ZIMBRA=./home-zimbra` - This is the example value from `DOT-env`.
- `HOME_ZIMBRA=~/zimbra` - This would mount a folder called `zimbra`, located in the `$HOME` directory of your host account to `/home/zimbra` in your `zcs-dev` container.

The setting for `REPO_DIR` should _not_ normally be changed in most cases.  If you do have to change it (due to considerations that are described in the `DOT-env` template file) be sure that the path that you use still ends up pointing to the the actual `docker-zcs-dev-machine` directory.


**Important!** Please read the notes in the `DOT-env` file for special considerations if you are running _Docker for Windows_ and are executing docker commands from within a _Windows Subsystem for Linux_ (WSL) shell!!

### SOLR-related Environment Variables

The `SOLR_MODE` environment variable controls how _SOLR_ will be started and how ZCS connects to it.  Valid values for his setting are:

- `cloud`
- `standalone`

The `SOLR_MEMORY` environment variable controls how much RAM is allocated to the _SOLR_ process.

Here are the defaults (from the `DOT-env` file that you copy to `.env`):

	SOLR_MODE=cloud
	SOLR_MEMORY=2g

## special directories

### home-zimbra

This directory is mounted into the `zcs-dev` container as
`/home/zimbra` if you use the default value from `DOT-env` as the
value you put in `.env`. This follows the conventions described in the
`README` file of [zm-build](https://github.com/Zimbra/zm-build).  You
can checkout the various Zimbra git repositories that you are working
with in their and all that will be preserved when you restart the
container.

### slash-zimbra/opt-zimbra/DOT-ssh

This directory is empty (save for a `.readme` file).  If you put your
keys here before you run the container they will be copied over to 
`/opt/zimbra/.ssh`.  This directory is in the `.gitignore` file so you
don't accidentally commit ssh keys to the git repo.

## Running the system

Just do a `docker-compose up -d` to start your development containers.

Once the `docker-compose up -d` command returns, the containers are running.
But the `zcs-dev` container will not be fully operational until it finishes
the run time initialization.  This takes about 1 minute. The majority of the time
required to complete the initialization is with starting the Zimbra services.

You can run this command to observe the initialization progress:

    docker logs -f zcs-dev

Once you see  this, the `zcs-dev` container will be fully operational:

    STARTUP COMPLETE

If you like, just combine the two commands:

    docker-compose up -d && docker logs -f zcs-dev

You can then connect to that container as follows:

    docker exec -it zcs-dev bash

And become the `zimbra` user as follows:

    su - zimbra

## Resetting base ZCS Install

With a recent upgrade to the `develop` branch, the system now creates a Docker volume that is
mounted into the running `zcs-dev` container at `/opt/zimbra`.  That, along with some 
minor updates to the entrypoint script, enables the system to retain all changes that
you might have deployed into the ZCS system as well as any other changes you may have made.

These changes will persist across container stopping and starting. If you wish to have the
base ZCS install cleanly reset--like if you totally bork it--all you need to do is shut down
the container,  delete the docker volume, and start it back up.  This is what it will 
look like:

    $ docker volume ls | grep opt_zimbra
    local               dockerzcsdevmachine_opt_zimbra

As you can see, the Docker volume that is created for the `zcs-dev` container
is called `dockerzcsdevmachine_opt_zimbra`.  To delete it:

    docker volume rm dockerzcsdevmachine_opt_zimbra

Similarly, with a recent update to the `feature/solr` branch, we now persist the
SOLR data in a Docker volume:

    $ docker volume ls | grep idx
    local               dockerzcsdevmachine_idxvolume

So you would also want to delete that Docker volume as well.

## Miscellaneous Notes

To stop your container, just do this:

    docker-compose down

As an alternative to stopping the container when you are not actively working
on it, you can pause it to reduce resource consumption (`docker-compose pause`)
an unpause it when you want to use it (`docker-compose unpause`).

You should edit the `/etc/hosts` file on your, um, host and add a line like this:

    127.0.0.1   zcs-dev.test

Then you can log into the web client on `zcs-dev` from a browser with the following
URL:

    https://zcs-dev.test:8443

Take a look at the `docker-compose.yml` file to see all of the port mappings.

If you need help seeing up a development environment, please take a look at [Setting up Eclipse and ItelliJ Community Edition](https://github.com/Zimbra/zm-mailbox/wiki/Setting-up-Eclipse-and-IntelliJ-IDEA-Community-Edition)

Your container also has all of the dependencies needed to build the installer.  Here is a quick about building the installer as the `zimbra` user:

- Make sure that the permissions of the top-level directory (from which you are running the build) are set to `755`.
- Make sure the output of the `umask` command for the user that is creating the build (`zimbra` in this case) is `0022`.  If it is not, enter `umask 0022` before running the build script.


## Performance Notes

There are known performance issues with [bind mounts](https://docs.docker.com/engine/admin/volumes/bind-mounts/) when using Docker on non-Linux hosts.  The _docker-zcs-dev-machine_ currently makes use of bind mounts as a convenience to the developer. It allows one to edit files from the host operating system and have those changes be available inside the running container.  The down side is that on non-Linux hosts, it takes longer to do builds, etc., because the container build process is reading from and writing to the mounted directory. What follows are a couple of suggestions that can _dramatically_ improve the performance.

### Volume caching

The easiest thing to do, if you have Mac host, is to just enable one of the volume caching options in your `docker-compose.yml` file, as follows:

    $ git diff
    diff --git a/docker-compose.yml b/docker-compose.yml
    index 59ee00c..4548c7c 100644
    --- a/docker-compose.yml
    +++ b/docker-compose.yml
    @@ -8,7 +8,7 @@ services:
           - /zimbra/init
         volumes:
           - $REPO_DIR/slash-zimbra:/zimbra
    -      - $HOME_ZIMBRA:/home/zimbra
    +      - $HOME_ZIMBRA:/home/zimbra:delegated
         container_name: zcs-dev
         domainname: test
         hostname: zcs-dev

As you can see from the diff, I just added `:delegated` to the end of the `/home/zimbra` volume mount.  To read more about the various caching options, please refer to the following references:

- [CACHING OPTIONS FOR VOLUME MOUNTS - DOCKER FOR MAC](https://docs.docker.com/compose/compose-file/#caching-options-for-volume-mounts-docker-for-mac)
- [Tuning with consistent, cached, and delegated configurations](https://docs.docker.com/docker-for-mac/osxfs-caching/#tuning-with-consistent-cached-and-delegated-configurations)

On my Mac host, execution times for cleaning, building, deploying locally, and publishing all of the sub-components of `zm-mailbox` went from `4m10s` to `1m30s`.

### Docker Volumes

If you want even better performance on non-Linux hosts, you can do so at the cost of a little inconvenience. Basically you have to copy the files that you want from your host to your container.  You can, of course, just **checkout the repos from the container directly**.

#### Enable Docker Volumes

To enable this option, just apply the following changes. First, to the `docker-compose.yml` file:

    $ git diff docker-compose.yml
    diff --git a/docker-compose.yml b/docker-compose.yml
    index 59ee00c..a013f03 100644
    --- a/docker-compose.yml
    +++ b/docker-compose.yml
    @@ -8,7 +8,7 @@ services:
           - /zimbra/init
         volumes:
           - $REPO_DIR/slash-zimbra:/zimbra
    -      - $HOME_ZIMBRA:/home/zimbra
    +      - home_zimbra:/home/zimbra:delegated
         container_name: zcs-dev
         domainname: testn
         hostname: zcs-dev
    @@ -31,3 +31,6 @@ networks:
           driver: default
           config:
             - subnet: 10.0.0.0/24
    +
    +volumes:
    +  home_zimbra: {}

Then, to the file `update-zimbra`, located in the `slash-zimbra` directory in the repo:

    $ git diff slash-zimbra/update-zimbra
    diff --git a/slash-zimbra/update-zimbra b/slash-zimbra/update-zimbra
    index b74b3f6..aebe46c 100755
    --- a/slash-zimbra/update-zimbra
    +++ b/slash-zimbra/update-zimbra
    @@ -6,6 +6,7 @@
     # * GITNAME - Your first and last name.

     DN=$(dirname $0)
    +chown zimbra:zimbra /home/zimbra
     chown zimbra:zimbra /opt/zimbra/.
     chown zimbra:zimbra /opt/zimbra/.*
     chmod -R o+w /opt/zimbra/lib/


#### Copy using docker cp


On host:

    $ docker cp $HOST_REPO_DIR/zm-zcs zcs-dev:/home/zimbra/
    $ docker cp $HOST_REPO_DIR/zm-mailbox zcs-dev:/home/zimbra/
	$ docker exec zcs-dev chown -R zimbra:zimbra /home/zimbra
    $ docker exec -it zcs-dev bash

The reason for the _chown_ command is because without that you can have funky permissions on the directories/files you copied from the host to the container via the use of the `docker cp` command.  For example, the two directories I copied over in the above example had these permissions without "fixing" them after the copy:

On container:

    su - zimbra
    cd /home/zimbra

    $ ls -l
    total 8
    drwxr-xr-x 13 502 dialout 4096 Jan 26 14:20 zm-mailbox
    drwxr-xr-x  3 502 dialout 4096 Aug 18 20:23 zm-zcs


On my Mac host, execution times for cleaning, building, deploying locally, and publishing all of the sub-components of `zm-mailbox` went from `4m10s` to `0m52s`. 

#### Copy using scp or rsync

You may also `scp` or `rsync` files from the host to the container.  This is really convenient and you don't have any permissions issues with the `/home/zimbra/*` destination so long as you do so using the `zimbra` user.  Remember that Docker exposes container ports to this host using port mappings.  The default SSH port mapping, as defined in `docker-compose.yml` is `2222`.  Some example:

	ssh -p 2222 zimbra@localhost

Or, if you have added an entry in your `/etc/hosts` file on your host that maps the `zcs-dev.test` domain to `127.0.0.1`:

	ssh -p 2222 zimbra@zcs-dev.test

You can authenticate with a password or by putting a public key over on the container.  There is a mechanism already in place for doing this automatically.  Just add a file called `authorized_keys` to the repo directory `slash-zimbra/opt-zimbra/DOT-ssh/`.  It should contain the public key that you wish to use when connecting from your host.  As noted above, that directory is in `.gitignore` so you don't accidentally `git add` it.  Whatever you put in that `authorized_keys` files gets _appended_ to the file `/opt/zimbra/.ssh/authorized_keys`, so we don't accidentally overwrite what the Zimbra setup process puts there.

You can also add the repositories as extra remotes in your host copies of the repos.  For example:

    $ git remote -v
    origin  git@github.com:Zimbra/zm-mailbox.git (fetch)
    origin  git@github.com:Zimbra/zm-mailbox.git (push)
    zcs-dev ssh://zimbra@zcs-dev.test:2222/home/zimbra/zcs/zm-mailbox (fetch)
    zcs-dev ssh://zimbra@zcs-dev.test:2222/home/zimbra/zcs/zm-mailbox (push)

So you can `git fetch zcs-dev`, etc.  Very convenient.

## SOLR Support

So make sure you have read the _Additional Configuration/SOLR-related Environment Variables_ section above first. A convenient script has been provided for you to use to update the base ZCS deployment to support SOLR.  That script is located in the `bin` repo directory and is called `configure-zcs-for-solr`.  After you have brought up your dev cluster and ZCS is up and running, just copy that script over to the top-level directory where you have all of your Zimbra repos checked out.

Then, _make sure you read and follow_ the comments at the top of the script.  Then (while logged into the `zcs-dev` container), run the script (as `root`, from the top-level directory on the container where you have all of your repos checked-out and prepared according to the notes at the top of the script).

The script is pretty noisy so I would recommend running it as follows:

    ./configure-zcs-for-solr > /dev/null

The script outputs status messages as it does its work to _stderr_ so you will be kept informed as it runs.
