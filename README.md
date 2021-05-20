# Hello Go

## App

Basic go webserver, containerized with docker.

Exposes on 8180.

### Run

```sh
go run hello.go
```

### Test

```sh
go test
```

### Build

```sh
docker build .
```


## Infrastructure 

Infrastructure is setup and managed by Terraform

### Basic Commands

Move into .infrastructure folder:

```sh
cd ./.infrastructure
```

Initialize folder:

```sh
terraform init
```

Create plan, see drift:
```
terraform plan
```