lambda_configs = [{
  name     = "estacionamientoCreate"
  handler  = "estacionamientoCreate.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoCreate.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoGetByRegion"
  handler  = "estacionamientoGetByRegion.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoGetByRegion.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoGetById"
  handler  = "estacionamientoGetById.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoGetById.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoEditParking"
  handler  = "estacionamientoEditParking.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoEditParking.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoOccupyLot"
  handler  = "estacionamientoOccupyLot.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoOccupyLot.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoFreeLot"
  handler  = "estacionamientoFreeLot.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoFreeLot.zip"
  role     = "LabRole"
  variables = {
    table_name = "estacionamiento"
  }
}]

api_endpoints = [
  {
    name        = "estacionamientoCreate"
    method      = "POST"
    path        = "/parking/{region}"
    lambda_name = "estacionamientoCreate"
  },
  {
    name        = "estacionamientoGetByRegion"
    method      = "GET"
    path        = "/parking/{region}"
    lambda_name = "estacionamientoGetByRegion"
  },
  {
    name        = "estacionamientoGetById"
    method      = "GET"
    path        = "/parking/{region}/{id}"
    lambda_name = "estacionamientoGetById"
  },
  {
    name        = "estacionamientoEditParking"
    method      = "PATCH"
    path        = "/parking/{region}/{id}"
    lambda_name = "estacionamientoEditParking"
  },
  {
    name        = "estacionamientoOccupyLot"
    method      = "POST"
    path        = "/parking/{region}/{id}/lot"
    lambda_name = "estacionamientoOccupyLot"
  },
  {
    name        = "estacionamientoFreeLot"
    method      = "DELETE"
    path        = "/parking/{region}/{id}/lot"
    lambda_name = "estacionamientoFreeLot"
  }
]
