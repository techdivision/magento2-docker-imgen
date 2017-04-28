# magento2-docker-imgen
This is a docker image generator for magento2 based on techdivision/dnmp-debian all in one webstack docker-image. It creates fully runnable magento2 installations with all services (nginx, mysql, redis etc.) included and preconfigured.

## Prerequisites
First you need to create an account at magento.com
Within the magento.com account you have to create access keys for magento2 under the marketplace tab

You need to have docker installed and of course... clone this repository.

## Usage
Make sure that you are in the repositories root folder

### Generate an magento2 image
You can define several build-arg's to configure your image for your needs. Just have a look into the ```Dockerfile``` if you want to know which build-args are available.

Lets say you want to create a magento2 community edition version 2.1.6 with sample-data included. This is how it looks like:
```bash
docker build \
    --build-arg MAGENTO_INSTALL_EDITION=community \
    --build-arg MAGENTO_INSTALL_VERSION=2.1.6 \
    --build-arg MAGENTO_INSTALL_SAMPLEDATA=1 \
    --build-arg MAGENTO_REPO_USERNAME=##YOUR_PUBLIC_ACCESS_KEY##
    --build-arg MAGENTO_REPO_PASSWORD=##YOUR_PRIVATE_ACCESS_KEY## \
    -t magento/magento2:v2.1.6 \
    .
```

Now you can push that image to your AWS ECR or other private docker registries.

If your magento.com account (Access Keys) has access to the enterprise edition you can also generate an image for that!

### Create a container instance from that image
When creating a container instance from that generated images you have to define the base-url of magento2 to run with. So you're able to easly run local as well as external magento2-app containers without any further configuration needed after container creation.
Perfect for automation things together with AWS ECS, ECR and Beanstalk for example.

Now lets run a magento2-app container with default settings and default base-url ```localhost``` listen on port ```80```, ```443``` and ```3306``` also on ```localhost```. Make sure that there is no service already listening on these ports. If yes just skip this and scroll a bit down to the next docker run example.
```bash
docker run \
    -p 80:80 \
    -p 443:443 \
    -p 3306:3306 \
    magento/magento2:v2.1.6
```
Wait until everything has booted up and check it on your browser:
[http://localhost/]()

If you want to remove the container after run just add ```--rm``` to the docker run command showen above.

If there is already a service listening on port 80 or the others binded to your local loopback address 127.0.0.1 (localhost) you can easly use another one like 127.0.1.1 for example.

If you're on Mac OS X together with Docker for Mac you have to create that additional local loopback ip as an alias before like this:
```bash
sudo ifconfig lo0 alias 127.0.1.1;
```

Now lets say we want to run a magento2-app conainter with the custom base-url ```magento2-app.dev``` on that additional loopback ip address ```127.0.1.1``` we created before or want to use if we're under linux.

```bash
# add hostname to /etc/hosts file
echo "127.0.1.1 magento2-app.dev" | sudo tee -a /etc/hosts

# run docker container
docker run \
    -p 127.0.1.1:80:80 \
    -p 127.0.1.1:443:443 \
    -p 127.0.1.1:3306:3306 \
    -e MAGENTO_BASE_URL=magento2-app.dev \
    magento/magento2:v2.1.6
```
Wait until everything has booted up and check it on your browser:
[http://magento2-app.dev/]()








