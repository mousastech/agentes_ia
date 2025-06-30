# Databricks notebook source
# MAGIC %pip install -U databricks-sdk langchain-community langchain-openai mlflow faker pdfplumber
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

catalog = "funcionesai"
dbName = db = "agents_demo"

# COMMAND ----------

def use_and_create_db(catalog, dbName, cloud_storage_path = None):
      print(f"USE CATALOG `{catalog}`")
      spark.sql(f"USE CATALOG `{catalog}`")
      spark.sql(f"""create database if not exists `{dbName}` """)
      spark.sql(f"USE `{catalog}`.`{db}`")


use_and_create_db(catalog,dbName)

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_weather(latitude DOUBLE, longitude DOUBLE, dtday STRING)
# MAGIC RETURNS STRUCT<temperature_in_celsius DOUBLE, precipitation_mm DOUBLE, precipitation STRING>
# MAGIC LANGUAGE PYTHON
# MAGIC COMMENT 'This function retrieves the forecast wather and return the temperature in celcius, preicipitation in mm and rain information for a given latitude and longitude using the Open-Meteo API.'
# MAGIC AS
# MAGIC $$
# MAGIC   try:
# MAGIC     import requests as r
# MAGIC     timezone = "America/Sao_Paulo"
# MAGIC     
# MAGIC     url = f"https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,rain_sum,wind_speed_10m_max&timezone={timezone}&start_date={dtday}&end_date={dtday}"
# MAGIC
# MAGIC     # Fazer a requisição
# MAGIC     response = r.get(url)
# MAGIC
# MAGIC     # Extrair a resposta JSON
# MAGIC     data = response.json()
# MAGIC
# MAGIC     precipitation = data['daily']['precipitation_sum'][0]
# MAGIC
# MAGIC     if precipitation > 0:
# MAGIC         return_precipitation = "yes"
# MAGIC     else:
# MAGIC         return_precipitation = "no"
# MAGIC
# MAGIC     return {
# MAGIC       "temperature_in_celsius": data['daily']['temperature_2m_max'][0],
# MAGIC       "precipitation_mm": precipitation,
# MAGIC       "precipitation": return_precipitation
# MAGIC     }
# MAGIC   except:
# MAGIC     return {"temperature_in_celsius": 25.0, "precipitation_mm": 4.3, "precipitation": "yes"}
# MAGIC
# MAGIC $$;
# MAGIC

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_historical_weather(latitude DOUBLE, longitude DOUBLE, start_date STRING, end_date STRING)
# MAGIC RETURNS STRUCT<temperature_in_celsius DOUBLE, precipitation_mm DOUBLE, precipitation STRING>
# MAGIC LANGUAGE PYTHON
# MAGIC COMMENT 'This function retrieves the historical data for temperature in celcius, preicipitation and rain information for a given latitude and longitude using the Open-Meteo API up to 10 years.'
# MAGIC AS
# MAGIC $$
# MAGIC   try:
# MAGIC     import requests as r
# MAGIC     timezone = "America/Sao_Paulo"
# MAGIC     
# MAGIC     url = f"https://historical-forecast-api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&start_date={start_date}&end_date={end_date}&daily=temperature_2m_max,precipitation_sum&timezone={timezone}"
# MAGIC
# MAGIC     # Fazer a requisição
# MAGIC     response = r.get(url)
# MAGIC
# MAGIC     # Extrair a resposta JSON
# MAGIC     data = response.json()
# MAGIC
# MAGIC     precipitation = data['daily']['precipitation_sum'][0]
# MAGIC
# MAGIC     if precipitation > 0:
# MAGIC         return_precipitation = "yes"
# MAGIC     else:
# MAGIC         return_precipitation = "no"
# MAGIC
# MAGIC     return {
# MAGIC       "temperature_in_celsius": data['daily']['temperature_2m_max'][0],
# MAGIC       "precipitation_mm": precipitation,
# MAGIC       "precipitation": return_precipitation
# MAGIC     }
# MAGIC   except:
# MAGIC     return {"temperature_in_celsius": 25.0, "precipitation_mm": 4.3, "precipitation": "yes"}
# MAGIC
# MAGIC $$;
# MAGIC

# COMMAND ----------

# DBTITLE 1,Consulta la temperatura en Ciudad de Mexico
# MAGIC %sql
# MAGIC SELECT get_weather(-19.4326, -99.1332, '2025-02-01')

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT get_historical_weather(-23.5505, -46.6333, '2024-01-31', '2024-02-10')

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_coordinates_from_cep(cep STRING)
# MAGIC RETURNS STRUCT<latitude DOUBLE, longitude DOUBLE>
# MAGIC LANGUAGE PYTHON
# MAGIC COMMENT 'This function retrieves the latitude and longitude for a given Brazilian postal code (CEP) using a geolocation API.'
# MAGIC AS
# MAGIC $$
# MAGIC   import requests as r
# MAGIC
# MAGIC   url = f"https://cep.awesomeapi.com.br/json/{cep}"
# MAGIC   
# MAGIC   response = r.get(url)
# MAGIC   
# MAGIC   if response.status_code == 200:
# MAGIC       data = response.json()
# MAGIC       
# MAGIC       if data:
# MAGIC           latitude = float(data['lat'])
# MAGIC           longitude = float(data['lng'])
# MAGIC           
# MAGIC           return {"latitude": latitude, "longitude": longitude}
# MAGIC       else:
# MAGIC           return {"latitude": -23.5502784, "longitude": -46.6342179}
# MAGIC   else:
# MAGIC       return {"latitude": -23.5502784, "longitude": -46.6342179}
# MAGIC $$;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_coordinates_from_postalcode(postalcode STRING)
# MAGIC RETURNS STRUCT<latitude DOUBLE, longitude DOUBLE>
# MAGIC LANGUAGE PYTHON
# MAGIC COMMENT 'This function retrieves the latitude and longitude for a given Mexican postal code using a geolocation API.'
# MAGIC AS
# MAGIC $$
# MAGIC import requests as r
# MAGIC
# MAGIC url = f"https://api.zippopotam.us/MX/{postalcode}"
# MAGIC
# MAGIC response = r.get(url)
# MAGIC
# MAGIC if response.status_code == 200:
# MAGIC     data = response.json()
# MAGIC     
# MAGIC     if data and 'places' in data and len(data['places']) > 0:
# MAGIC         latitude = float(data['places'][0]['latitude'])
# MAGIC         longitude = float(data['places'][0]['longitude'])
# MAGIC         
# MAGIC         return {"latitude": latitude, "longitude": longitude}
# MAGIC     else:
# MAGIC         return {"latitude": 19.432608, "longitude": -99.133209}  # Default coordinates for Mexico City
# MAGIC else:
# MAGIC     return {"latitude": 19.432608, "longitude": -99.133209}  # Default coordinates for Mexico City
# MAGIC $$;

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT get_coordinates_from_postalcode("99998")

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_delayed_or_cancelled_flights(start_date STRING, end_date STRING, sigla_icao_aero_origem STRING, sigla_icao_aero_destino STRING)
# MAGIC RETURNS TABLE (
# MAGIC     sigla_icao_empresa_aerea STRING,
# MAGIC     empresa_aerea STRING,
# MAGIC     numero_voo STRING,
# MAGIC     sigla_icao_aeroporto_origem STRING,
# MAGIC     desc_aeroporto_origem STRING,
# MAGIC     partida_prevista TIMESTAMP,
# MAGIC     partida_real TIMESTAMP,
# MAGIC     sigla_icao_aeroporto_destino STRING,
# MAGIC     desc_aeroporto_destino STRING,
# MAGIC     chegada_prevista TIMESTAMP,
# MAGIC     chegada_real TIMESTAMP,
# MAGIC     situacao_voo STRING,
# MAGIC     justificativa STRING
# MAGIC )
# MAGIC COMMENT 'This function retrieves flights that were delayed by more than 2 hours or canceled within a specified date range and between specified origin and destination airports.'
# MAGIC RETURN
# MAGIC SELECT 
# MAGIC     sigla_icao_empresa_aerea,
# MAGIC     empresa_aerea,
# MAGIC     numero_voo,
# MAGIC     sigla_icao_aeroporto_origem,
# MAGIC     desc_aeroporto_origem,
# MAGIC     partida_prevista,
# MAGIC     partida_real,
# MAGIC     sigla_icao_aeroporto_destino,
# MAGIC     desc_aeroporto_destino,
# MAGIC     chegada_prevista,
# MAGIC     chegada_real,
# MAGIC     situacao_voo,
# MAGIC     justificativa
# MAGIC FROM 
# MAGIC     tnovais_demos.demo_anac.voo_regular_ativo
# MAGIC WHERE 
# MAGIC     (UPPER(situacao_voo) = 'CANCELADO' OR 
# MAGIC     (partida_real IS NOT NULL AND partida_real > partida_prevista + INTERVAL 2 HOUR) OR 
# MAGIC     (chegada_real IS NOT NULL AND chegada_real > chegada_prevista + INTERVAL 2 HOUR))
# MAGIC     AND partida_prevista BETWEEN start_date AND end_date
# MAGIC     AND sigla_icao_aeroporto_origem ILIKE sigla_icao_aero_origem
# MAGIC     AND sigla_icao_aeroporto_destino ILIKE sigla_icao_aero_destino;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE FUNCTION get_delayed_or_cancelled_flights_mx(start_date STRING, end_date STRING, sigla_icao_aero_origem STRING, sigla_icao_aero_destino STRING)
# MAGIC RETURNS TABLE (
# MAGIC     sigla_icao_empresa_aerea STRING,
# MAGIC     empresa_aerea STRING,
# MAGIC     numero_voo STRING,
# MAGIC     sigla_icao_aeroporto_origem STRING,
# MAGIC     desc_aeroporto_origem STRING,
# MAGIC     partida_prevista TIMESTAMP,
# MAGIC     partida_real TIMESTAMP,
# MAGIC     sigla_icao_aeroporto_destino STRING,
# MAGIC     desc_aeroporto_destino STRING,
# MAGIC     chegada_prevista TIMESTAMP,
# MAGIC     chegada_real TIMESTAMP,
# MAGIC     situacao_voo STRING,
# MAGIC     justificativa STRING
# MAGIC )
# MAGIC COMMENT 'This function retrieves flights that were delayed by more than 2 hours or canceled within a specified date range and between specified origin and destination airports.'
# MAGIC RETURN
# MAGIC SELECT 
# MAGIC     sigla_icao_empresa_aerea,
# MAGIC     empresa_aerea,
# MAGIC     numero_voo,
# MAGIC     sigla_icao_aeroporto_origem,
# MAGIC     desc_aeroporto_origem,
# MAGIC     partida_prevista,
# MAGIC     partida_real,
# MAGIC     sigla_icao_aeroporto_destino,
# MAGIC     desc_aeroporto_destino,
# MAGIC     chegada_prevista,
# MAGIC     chegada_real,
# MAGIC     situacao_voo,
# MAGIC     justificativa
# MAGIC FROM 
# MAGIC     funcionesai.agents_demo.vuelos_regulares
# MAGIC WHERE 
# MAGIC     (UPPER(situacao_voo) = 'CANCELADO' OR 
# MAGIC     (partida_real IS NOT NULL AND partida_real > partida_prevista + INTERVAL 2 HOUR) OR 
# MAGIC     (chegada_real IS NOT NULL AND chegada_real > chegada_prevista + INTERVAL 2 HOUR))
# MAGIC     AND partida_prevista BETWEEN start_date AND end_date
# MAGIC     AND sigla_icao_aeroporto_origem ILIKE sigla_icao_aero_origem
# MAGIC     AND sigla_icao_aeroporto_destino ILIKE sigla_icao_aero_destino;

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT 
# MAGIC     sigla_icao_empresa_aerea,
# MAGIC     empresa_aerea,
# MAGIC     numero_voo,
# MAGIC     sigla_icao_aeroporto_origem,
# MAGIC     desc_aeroporto_origem,
# MAGIC     partida_prevista,
# MAGIC     partida_real,
# MAGIC     sigla_icao_aeroporto_destino,
# MAGIC     desc_aeroporto_destino,
# MAGIC     chegada_prevista,
# MAGIC     chegada_real,
# MAGIC     situacao_voo,
# MAGIC     justificativa
# MAGIC FROM 
# MAGIC     funcionesai.agents_demo.vuelos_regulares

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM get_delayed_or_cancelled_flights('2022-01-01', '2022-01-31', 'SBGR', 'MMMX') as dc_flights

# COMMAND ----------

import requests

def get_coordinates_from_cep(cep):
    try:
        # URL para a API AwesomeAPI
        url = f"https://cep.awesomeapi.com.br/json/{cep}"
        
        # Requisição para a API
        response = requests.get(url)
        
        # Verifica se a resposta é válida
        if response.status_code == 200:
            data = response.json()
            
            # Verifica se os dados foram encontrados
            if data:
                latitude = float(data['lat'])
                longitude = float(data['lng'])
                return latitude, longitude
            else:
                print("Nenhum dado encontrado para o CEP fornecido.")
                return None, None
        else:
            print(f"Erro na requisição: {response.status_code}")
            return None, None
    
    except Exception as e:
        print(f"Erro: {e}")
        return None, None

# Exemplo de uso
cep = "13401-843"
latitude, longitude = get_coordinates_from_cep(cep)
print(f"Latitude: {latitude}, Longitude: {longitude}")

# COMMAND ----------



# COMMAND ----------

# MAGIC %sql
# MAGIC -- Generate fake data instead of calling the VS index with vector_search;
# MAGIC CREATE OR REPLACE FUNCTION extract_features_nfe(document STRING)
# MAGIC RETURNS TABLE (nome STRING, cpf STRING, produtos STRING)
# MAGIC COMMENT 'Esta função retorna o nome, cpf e produtos de um cliente a partir do texto do documento nota fiscal enviado pelo cliente.'
# MAGIC RETURN
# MAGIC SELECT doc_cliente.* FROM (
# MAGIC   SELECT explode(from_json(
# MAGIC     ai_query(
# MAGIC       'databricks-meta-llama-3-70b-instruct', 
# MAGIC       CONCAT(
# MAGIC         'Você é um especialista em extrair informações de documento de usuário com informações extraídas a partir de um texto PDF. Extraia o CPF, nome do usuário e o nome dos produtos (apenas o nome do produto, nenhum outro detalhe) e retorne uma lista json com o seguinte formato: <"nome": string, "cpf": string, "produtos": list>. 
# MAGIC         Exemplo de formatação para retornar os dados Nome: Larissa Xavier, CPF: 122333444-12, PRODUTOS: Geladeira, TV, Smartphone. 
# MAGIC         Documento para extrair informações:', document,'. 
# MAGIC         Retorna apenas a resposta como um objeto json javascript pronto para ser parsed, sem comentários ou texto ou javascript ou ``` no início' 
# MAGIC       ) 
# MAGIC     ), 
# MAGIC     'ARRAY<STRUCT<nome: STRING, cpf: STRING, produtos: STRING>>' )) AS doc_cliente );
