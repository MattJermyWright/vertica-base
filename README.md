## Build Vertica Docker Instance

Greatly inspired by work done by sumitchawla/vertica - but I wanted something that worked with Vertica 8 and that seemed to work for persistent stores.

### Prerequisites
- RPM of Vertica install (http://my.vertica.com)
- Docker
- Patience

### Standard Build Instructions

`docker build -t vertica/main .`

#### Start the server (Non-Persistent) 

`docker run -p 5433:5433 -d vertica/main`

#### Start the server with persistent catalog on exit
    export datadir=`pwd`/data
    docker run -p 5433:5433 -d -v $datadir:/home/dbadmin/docker vertica/main

### Connection String
    jdbc:vertica://VerticaHost:portNumber/databaseName
    jdbc:vertica://localhost:5433/docker

Username: dbadmin, no password

### Loading Files

**Tab Delimited File**
        
    vsql -h localhost -p 5433 -U dbadmin -c "copy public.mjw_tmp_csdblog from local '/Users/matt/Desktop/shr2_vrt_pro_hpcom_usr_mjw_tmp_csdblog.tsv' delimiter E'\t'"
