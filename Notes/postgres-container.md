#### Run
`docker run --name whatever-postgres -p 5432:5432 -e POSTGRES_PASSWORD=mysecretpassword -d postgres`

#### Connect
`postgresql://postgres:mysecretpassword@localhost:5432/postgres`

