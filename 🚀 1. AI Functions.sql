-- Databricks notebook source
-- MAGIC %md <img src="https://github.com/mousastech/iafunciones/blob/a29291ca12bdaace778eb9dc8b70ee301cd9bf7e/img/headertools_aifunctions.png?raw=true" width=100%>
-- MAGIC
-- MAGIC # Análisis de sentimiento, extracción de entidades y generación de texto.
-- MAGIC
-- MAGIC Capacitación práctica en la plataforma Databricks con enfoque en funcionalidades de IA generativa.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Objetivos del ejercicio
-- MAGIC
-- MAGIC El objetivo de este laboratorio es implementar el siguiente caso de uso:
-- MAGIC
-- MAGIC ### Aumentar la satisfacción del cliente con el análisis automático de reseñas
-- MAGIC
-- MAGIC En este laboratorio, crearemos un canal de datos que toma las opiniones de los clientes, en formato de texto libre, y las enriquece con información extraída haciendo preguntas en lenguaje natural a los modelos de IA generativa disponibles en Databricks. También brindaremos recomendaciones para las siguientes mejores acciones a nuestro equipo de servicio al cliente, es decir, si un cliente requiere seguimiento y un borrador de mensaje de respuesta.
-- MAGIC
-- MAGIC Para cada evaluación, nosotros:
-- MAGIC
-- MAGIC - Identificamos el sentimiento del cliente y extraemos los productos mencionados.
-- MAGIC - Generamos una respuesta personalizada para el cliente
-- MAGIC
-- MAGIC <img src="https://raw.githubusercontent.com/databricks-demos/dbdemos-resources/main/images/product/sql-ai-functions/sql-ai-query-function-review.png" width="100%">

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Preparación
-- MAGIC
-- MAGIC Para realizar los ejercicios, necesitamos prende un Clúster.
-- MAGIC
-- MAGIC Simplemente siga los pasos a continuación:
-- MAGIC 1. En la esquina superior derecha, haga clic en **Conectar**
-- MAGIC 2. Seleccione el tipo de Clúster **SQL Serverless Warehouse** o **Serverless**.

-- COMMAND ----------

-- MAGIC %md 
-- MAGIC
-- MAGIC ## Conjunto de datos de ejemplo
-- MAGIC
-- MAGIC Ahora, accedamos a las reseñas de productos que subimos en la práctica de laboratorio anterior.
-- MAGIC
-- MAGIC En esta práctica de laboratorio usaremos dos tablas:
-- MAGIC - **Resenas**: datos no estructurados con el contenido de las evaluaciones
-- MAGIC - **Clientes**: datos estructurados como registro de clientes y consumo.
-- MAGIC
-- MAGIC ¡Ahora visualicemos estos datos!

-- COMMAND ----------

-- MAGIC %md ### A. Preparación de datos
-- MAGIC
-- MAGIC 1. Crear o utilizar el catalogo `agents_ia`
-- MAGIC 2. Crear o utilizar el schema `atencion`
-- MAGIC 3. Crear el volumen `archivos`
-- MAGIC 4. Importar los archivos de la carpeta `data` para el Volumen creado

-- COMMAND ----------

USE agents_ia.atencion

-- COMMAND ----------

-- MAGIC %md ### B. Ver la tabla de calificaciones

-- COMMAND ----------

SELECT * FROM resenas

-- COMMAND ----------

-- MAGIC %md ### C. Ver la tabla de clientes

-- COMMAND ----------

SELECT * FROM clientes

-- COMMAND ----------

-- MAGIC %md ## A. Analizar el sentimiento y extraer información.
-- MAGIC
-- MAGIC Nuestro objetivo es permitir un análisis rápido de grandes volúmenes de reseñas de forma rápida y eficiente. Para hacer esto, necesitamos extraer la siguiente información:
-- MAGIC
-- MAGIC - Productos mencionados
-- MAGIC - Sentimiento del cliente
-- MAGIC - En caso negativo, ¿cuál es el motivo de la insatisfacción?
-- MAGIC
-- MAGIC Veamos cómo podemos aplicar la IA generativa para acelerar nuestro trabajo.
-- MAGIC
-- MAGIC | Gen AI SQL Function | Descrição |
-- MAGIC | -- | -- |
-- MAGIC | [ai_analyze_sentiment](https://docs.databricks.com/pt/sql/language-manual/functions/ai_analyze_sentiment.html) | Análisis de sentimiento |
-- MAGIC | [ai_classify](https://docs.databricks.com/pt/sql/language-manual/functions/ai_classify.html) | Clasifica el texto según categorías definidas. |
-- MAGIC | [ai_extract](https://docs.databricks.com/pt/sql/language-manual/functions/ai_extract.html) | Extraiga las entidades deseadas |
-- MAGIC | [ai_fix_grammar](https://docs.databricks.com/pt/sql/language-manual/functions/ai_fix_grammar.html) | Corrige a gramática do texto fornecido |
-- MAGIC | [ai_gen](https://docs.databricks.com/pt/sql/language-manual/functions/ai_gen.html) | Corrige la gramática del texto proporcionado. | 
-- MAGIC | [ai_mask](https://docs.databricks.com/pt/sql/language-manual/functions/ai_mask.html) | Enmascarar datos confidenciales |
-- MAGIC | [ai_query](https://docs.databricks.com/pt/sql/language-manual/functions/ai_query.html) | Enviar instrucciones para el modelo deseado. |
-- MAGIC | [ai_similarity](https://docs.databricks.com/pt/sql/language-manual/functions/ai_similarity.html) | Calcula la similitud entre dos expresiones. |
-- MAGIC | [ai_summarize](https://docs.databricks.com/pt/sql/language-manual/functions/ai_summarize.html) | Resume el texto dado. |
-- MAGIC | [ai_translate](https://docs.databricks.com/pt/sql/language-manual/functions/ai_translate.html) | Traduce el texto proporcionado |

-- COMMAND ----------

-- MAGIC %md 
-- MAGIC #### 🚀 Análisis de sentimiento

-- COMMAND ----------

SELECT *, 
       ai_analyze_sentiment(avaliacao) AS sentimiento 
FROM resenas 
WHERE avaliacao IS NOT NULL 

-- COMMAND ----------

-- MAGIC %md #### 📝 Traducción

-- COMMAND ----------

-- DBTITLE 1,Ejemplo
SELECT ai_translate(avaliacao, 'es') texto FROM resenas LIMIT 10

-- COMMAND ----------

-- DBTITLE 1,Uso de ai_translate en una función
SELECT  *, ai_translate(avaliacao, 'es') AS sentimento FROM resenas LIMIT 10

-- COMMAND ----------

-- DBTITLE 1,Crear tabla de reseñas traducida
CREATE TABLE resenas_es as 
SELECT data as fecha,
       id_avaliacao as id_resena,
       id_cliente,
       ai_translate(avaliacao, 'es') AS resena,
       ai_query(
  'databricks-meta-llama-3-3-70b-instruct',
  concat('Si el sentimiento de evaluación es negativo, enumere los motivos de la insatisfacción en español. Evaluación: ', avaliacao)) AS motivo_insatisfaccion
FROM resenas

-- COMMAND ----------

select * from resenas_es LIMIT 10

-- COMMAND ----------

-- MAGIC %md #### 🔎 Extracción de los productos mencionados

-- COMMAND ----------

SELECT *, ai_extract(resena, ARRAY('producto')) AS productos FROM resenas_es LIMIT 10

-- COMMAND ----------

-- MAGIC %md ####  🔎 Extrayendo el motivo de la insatisfacción.
-- MAGIC
-- MAGIC *SUGERENCIA: Utilice la función AI_QUERY() para proporcionar un mensaje personalizado*

-- COMMAND ----------

-- DBTITLE 1,Para checar el idioma
SELECT *, ai_query(
  'databricks-meta-llama-3-3-70b-instruct',
  concat('Si el sentimiento de evaluación es negativo, enumere los motivos de la insatisfacción en español. Evaluación: ', avaliacao)) AS motivo_insatisfaccion
FROM resenas LIMIT 10

-- COMMAND ----------

-- DBTITLE 1,Comprobar en español
SELECT *,
       ai_query(
  'databricks-meta-llama-3-3-70b-instruct',
  concat('Si el sentimiento de evaluación es negativo, enumere los motivos de la insatisfacción en español. Evaluación: ', resena)) AS motivo_insatisfaccion
FROM resenas_es LIMIT 10

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### 🔎 Analizar el sentimiento y extraer entidades a escala
-- MAGIC
-- MAGIC Tener que especificar las instrucciones varias veces acaba siendo laborioso, especialmente para los Analistas de Datos que deben centrarse en analizar los resultados de esta extracción.
-- MAGIC
-- MAGIC Para simplificar el acceso a esta inteligencia, crearemos una función SQL para encapsular este proceso y poder informar simplemente a qué columna de nuestro conjunto de datos nos gustaría aplicarlo.
-- MAGIC
-- MAGIC ¡Aquí, aprovechemos para enviar una única consulta a nuestro modelo para extraer toda la información de una vez!
-- MAGIC
-- MAGIC <img src="https://raw.githubusercontent.com/databricks-demos/dbdemos-resources/main/images/product/sql-ai-functions/sql-ai-query-function-review-wrapper.png" width="1200px">

-- COMMAND ----------

-- MAGIC %md #### ✔️ Creando una función para extraer toda la información

-- COMMAND ----------

CREATE OR REPLACE FUNCTION revisar_resena(resena STRING)
RETURNS STRUCT<nombre_producto: STRING, sentimiento: STRING, respuesta: STRING, resposta_motivo: STRING>
RETURN FROM_JSON(
    AI_QUERY(
        'databricks-meta-llama-3-1-405b-instruct',
        CONCAT(
            'Um cliente fez uma avaliação. Respondemos a todos que parecem insatisfeitos.
            Extraia a seguinte informação:
            - classifique o sentimento como ["POSITIVO","NEGATIVO","NEUTRAL"]
            - retorne se o sentimento é NEGATIVO e precisa resposta: S ou N
            - se o sentimento é NEGATIVO, explique quais são os principais motivos
            Retorne apenas um JSON. Nenhum outro texto fora do JSON. Formato do JSON:
            {
              "nombre_producto": <nome entidade>,
              "sentimiento": <sentimento entidade>,
              "respuesta": <S ou N para resposta>,
              "resposta_motivo": <motivos de insatisfação>
            }
            Avaliação: ', resena
        )
    ),
    "STRUCT<nombre_producto: STRING, sentimiento: STRING, respuesta: STRING, resposta_motivo: STRING>"
)

-- COMMAND ----------

-- DBTITLE 1,Optional
--Se quieres, puedes cambiar a Español

 AI_QUERY(
    'databricks-meta-llama-3-1-405b-instruct',
    CONCAT(
      'Un cliente dejó una reseña. Respondemos a cualquiera que parezca insatisfecho.
        Extraiga la siguiente información:
        - extraer el producto
        - extraer la categoría del producto, por ejemplo: tableta, portátil, teléfono inteligente
        - clasificar el sentimiento como ["POSITIVO","NEGATIVO","NEUTRAL"]
        - regresar si el sentimiento es NEGATIVO y necesita una respuesta: S o N
        - si el sentimiento es NEGATIVO, explica las razones principales
        Devuelve solo un JSON. Ningún otro texto que no sea JSON. Formato JSON:
      {
        "nombre_producto": <entidade nombre>,
        "producto_categoria": <entidade categoria>,
        "sentimiento": <entidade sentimiento>,
        "respuesta": <S o N para respuestas>,
        "motivo": <razones de la insatisfacción>
      }
      Evaluación: ', resena
    )
  )
  "STRUCT<nombre_producto: STRING, sentimiento: STRING, respuesta: STRING, resposta_motivo: STRING>"
  )

-- COMMAND ----------

-- MAGIC %md #### ✔️ Análisis de revisión de pruebas

-- COMMAND ----------

SELECT revisar_resena('Compré el portátil ABC y estoy muy insatisfecho con la calidad de la pantalla. Los colores son débiles y la resolución es baja. Además, el rendimiento es lento y se bloquea con frecuencia. ¡No lo recomiendo!') AS resultado

-- COMMAND ----------

-- MAGIC %md #### ✔️  Analizando todas las reseñas

-- COMMAND ----------

-- DBTITLE 1,Crear una tabela de reseñas revisadas
CREATE OR REPLACE TABLE resenas_revisadas AS
SELECT *, resultado.* FROM (
  SELECT *, revisar_resena(resena) as resultado FROM agents_ia.atencion.resenas_es LIMIT 10)

-- COMMAND ----------

-- DBTITLE 1,Pruebar la función
SELECT *, revisar_resena(resena) as resultado FROM resenas_es limit 5

-- COMMAND ----------

-- MAGIC %md Ahora todos nuestros usuarios pueden aprovechar nuestra función cuidadosamente preparada para analizar las reseñas de nuestros productos.
-- MAGIC
-- MAGIC ¡Y podemos escalar fácilmente este proceso aplicando esta función a todo nuestro conjunto de datos!

-- COMMAND ----------

-- MAGIC %md ## 📝 Generando una respuesta sugerida
-- MAGIC
-- MAGIC Con toda la información extraída, podemos utilizarla para generar sugerencias de respuestas personalizadas para agilizar el trabajo de nuestros equipos de servicio.
-- MAGIC
-- MAGIC Otro punto interesante es que, en este proceso, podemos aprovechar otra **información estructurada** que ya tenemos en nuestro entorno, como datos demográficos, psicográficos e historial de compras, ¡para personalizar aún más nuestras respuestas!
-- MAGIC
-- MAGIC ¡Veamos cómo hacerlo!

-- COMMAND ----------

-- MAGIC %md ### A. Crear una función para generar una respuesta de ejemplo

-- COMMAND ----------

CREATE OR REPLACE FUNCTION GENERE_RESPUESTA(nombre STRING, apellido STRING, num_pedidos INT, producto STRING, motivo STRING)
RETURNS TABLE(respuesta STRING)
COMMENT 'Si el cliente expresa insatisfacción con un producto, utilice esta función para generar una respuesta personalizada'
RETURN SELECT AI_QUERY(
    'databricks-meta-llama-3-1-70b-instruct',
    CONCAT(
        "Eres un asistente virtual para un comercio electrónico. Nuestro cliente, ", GENERE_RESPUESTA.nombre, " ", GENERE_RESPUESTA.apellido, " quien compró ", GENERE_RESPUESTA.num_pedidos, " productos este año no estaba satisfecho con el producto ", GENERE_RESPUESTA.producto, 
        ", pues ", GENERE_RESPUESTA.motivo, ". Proporcionar un breve mensaje empático al cliente incluyendo una oferta para cambiar el producto si cumple con nuestra política de cambio. El canje se podrá realizar directamente a través de este asistente. ",
        "Quiero recuperar su confianza y evitar que deje de ser nuestro cliente. ",
        "Escribe un mensaje con algunas frases. ",
        "No agregue ningún texto que no sea el mensaje. ",
        "No agregues ninguna firma."
    )
)

-- COMMAND ----------

-- MAGIC %md ### B. Generar respuestas automáticas a todas las críticas negativas

-- COMMAND ----------

CREATE OR REPLACE TABLE respuestas AS
WITH avaliacoes_enriq AS (
  SELECT a.*, c.* EXCEPT (c.id_cliente) 
  FROM resenas_revisadas a 
  LEFT JOIN clientes c 
  ON a.id_cliente = c.id_cliente 
  WHERE a.respuesta = 'S' 
  LIMIT 10
)

SELECT 
  *, 
  (SELECT * FROM genere_respuesta(e.nome, e.sobrenome, e.num_pedidos, e.nombre_producto, e.resposta_motivo)) AS bosquejo 
FROM avaliacoes_enriq e

-- COMMAND ----------

-- DBTITLE 1,Revisar el bosquejo
SELECT bosquejo from respuestas

-- COMMAND ----------

-- MAGIC %md # ¡Felicidades!
-- MAGIC
-- MAGIC ¡Ha completado la práctica de laboratorio de **Extracción de información y generación de texto**!
-- MAGIC
-- MAGIC ¡Ahora ya sabe cómo utilizar funciones de IA para analizar sentimientos e identificar entidades en reseñas de productos de una manera simple y escalable!
