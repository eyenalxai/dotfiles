#### Init
`alembic init -t async .migrations`

#### Generate migration
`alembic revision --autogenerate -m "msg"`

#### Apply migration
`alembic upgrade head`
