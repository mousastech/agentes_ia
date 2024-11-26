-- Databricks notebook source
-- MAGIC %md <img src="https://github.com/Databricks-BR/lab_genai/blob/main/img/header.png?raw=true" width=100%>
-- MAGIC
-- MAGIC # Usando Agentes de IA
-- MAGIC
-- MAGIC Capacitación práctica en la plataforma Databricks con enfoque en funcionalidades de IA generativa.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Objetivos del ejercicio
-- MAGIC
-- MAGIC El objetivo de este laboratorio es implementar el siguiente caso de uso:
-- MAGIC
-- MAGIC ### Personalización del servicio con Agentes
-- MAGIC
-- MAGIC Los LLM son excelentes para responder preguntas. Sin embargo, esto por sí solo no es suficiente para ofrecer valor a sus clientes.
-- MAGIC
-- MAGIC Para poder proporcionar respuestas más complejas, se requiere información adicional específica del usuario, como su ID de contrato, el último correo electrónico que envió a su soporte o su informe de compra más reciente.
-- MAGIC
-- MAGIC Los agentes están diseñados para superar este desafío. Son despliegues de IA más avanzados, compuestos por múltiples entidades (herramientas) especializadas en diferentes acciones (recuperar información o interactuar con sistemas externos).
-- MAGIC
-- MAGIC En términos generales, usted crea y presenta un conjunto de funciones personalizadas a la IA. Luego, el LLM puede razonar sobre qué información debe recopilarse y qué herramientas utilizar para responder a las instrucciones que recibe.
-- MAGIC
-- MAGIC <img src="https://github.com/databricks-demos/dbdemos-resources/blob/main/images/product/llm-tools-functions/llm-tools-functions-flow.png?raw=true" width="100%">

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
-- MAGIC - **Evaluaciones**: datos no estructurados con el contenido de las evaluaciones
-- MAGIC - **Clientes**: datos estructurados como registro de clientes y consumo.
-- MAGIC
-- MAGIC ¡Ahora visualicemos estos datos!

-- COMMAND ----------

-- MAGIC %md ### A. Preparación de datos
-- MAGIC
-- MAGIC 1. Crear o utilizar el catalogo `tutorial`
-- MAGIC 2. Crear o utilizar el schema `carga`
-- MAGIC 3. Crear el volumen `archivos`
-- MAGIC 4. Importar los archivos de la carpeta `data` para el Volumen creado
-- MAGIC
-- MAGIC Código disponible en el notebook `⚙️ ./Setup`

-- COMMAND ----------

-- MAGIC %md ## Usando el Unity Catalog Tools
-- MAGIC
-- MAGIC El primer paso en la construcción de nuestro agente será entender cómo utilizar **Unity Catalog Tools**.
-- MAGIC
-- MAGIC En la práctica de laboratorio anterior, creamos algunas funciones, como `revisar_evaluacion`, que nos permitió facilitar la invocación de nuestros modelos de IA generativa desde SQL. Sin embargo, nuestros LLM también pueden utilizar estas mismas funciones como herramientas. ¡Simplemente indique qué funciones puede utilizar el modelo!
-- MAGIC
-- MAGIC Poder utilizar el mismo catálogo de herramientas en toda la plataforma nos simplifica enormemente la vida al promover la reutilización de estos activos. Esto puede ahorrar horas de remodelación y estandarizar estos conceptos.
-- MAGIC
-- MAGIC ¡Veamos cómo utilizar las herramientas en la práctica!
-- MAGIC
-- MAGIC 1. En el **menú principal** de la izquierda, haz clic en **`Playground`**
-- MAGIC 2. Haz clic en el **selector de modelo** y selecciona el modelo **`Meta Llama 3.1 70B Instruct`** (si aún no está seleccionado)
-- MAGIC 3. Hacer clic **Tools** y luego en **Add Tool** 
-- MAGIC 4. En **Hosted Function**, tipear `tutorial.carga.revisar_avaliacao`
-- MAGIC 5. Agregue instrucciones a continuación:
-- MAGIC     ```
-- MAGIC     Revise la reseña a continuación:
-- MAGIC  Compré una tableta y estoy muy descontento con la calidad de la batería. Dura muy poco y tarda mucho en cargarse.
-- MAGIC     ```
-- MAGIC 6. Haga clic en el ícono **enviar**

-- COMMAND ----------

-- MAGIC %md ## Consultando dados do cliente
-- MAGIC
-- MAGIC Ferramentas podem ser utilizadas em diversos cenários, como por exemplo:
-- MAGIC
-- MAGIC - Consultar informações em bancos de dados
-- MAGIC - Calcular indicadores complexos
-- MAGIC - Gerar um texto baseado nas informações disponíveis
-- MAGIC - Interagir com APIs e sistemas externos
-- MAGIC
-- MAGIC Como já discutimos, isso vai ser muito importante para conseguirmos produzir respostas mais personalizadas e precisas no nosso agente. 
-- MAGIC
-- MAGIC No nosso caso, gostaríamos de:
-- MAGIC - Consultar os dados do cliente
-- MAGIC - Pesquisar perguntas e respostas em uma base de conhecimento
-- MAGIC - Fornecer recomendações personalizadas de produtos com base em suas descrições
-- MAGIC
-- MAGIC Vamos começar pela consulta dos dados do cliente!

-- COMMAND ----------

-- MAGIC %md ### A. Seleccione la base de datos creada previamente

-- COMMAND ----------

USE funcionesai.carga

-- COMMAND ----------

-- MAGIC %md ### B. Crear la función

-- COMMAND ----------

CREATE OR REPLACE FUNCTION CONSULTAR_CLIENTE(id_cliente BIGINT)
RETURNS TABLE (nome STRING, sobrenome STRING, num_pedidos INT)
COMMENT 'Utilice esta función para consultar los datos de un cliente'
RETURN SELECT nome, sobrenome, num_pedidos FROM clientes c WHERE c.id_cliente = consultar_cliente.id_cliente

-- COMMAND ----------

-- MAGIC %md ### C. Probar la función

-- COMMAND ----------

SELECT * FROM consultar_cliente(1)

-- COMMAND ----------

-- MAGIC %md ### D. Testar a função como ferramenta
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Playground`**
-- MAGIC 2. Clique no **seletor de modelos** e selecione o modelo **`Meta Llama 3.1 70B Instruct`** (caso já não esteja selecionado)
-- MAGIC 3. Clique em **Tools** e depois em **Add Tool** 
-- MAGIC 4. Em **Hosted Function**, digite `tutorial.carga.consultar_cliente` e `academy.<seu_nome>.revisar_avaliacao`
-- MAGIC 5. Adicione a instrução abaixo:<br>
-- MAGIC     `Gere uma resposta para o cliente 1 que está insatisfeito com a qualidade da tela do seu tablet. Não esqueça de customizar a mensagem com o nome do cliente.`
-- MAGIC 6. Clique no ícone **enviar**

-- COMMAND ----------

-- MAGIC %md ### E. Analisando os resultados
-- MAGIC
-- MAGIC Com o resultado do exercício anterior, siga os passos abaixo:
-- MAGIC
-- MAGIC 1. Na parte inferior da resposta, clique em **`View Trace`** 
-- MAGIC 2. Neste painel, navegue entre as diferentes ações executadas à esquerda
-- MAGIC
-- MAGIC Dessa forma, você poderá entender a linha de raciocínio do agente, ou seja, quais ações foram executas, com quais parâmetros e em que ordem. Além disso, quando houver algum erro de execução, também servirá de insumo para entendermos e corrigirmos eventuais problemas.

-- COMMAND ----------

-- MAGIC %md ## Pesquisando perguntas e respostas em uma base de conhecimento
-- MAGIC
-- MAGIC Agora, precisamos prepara uma função que nos permita aproveitar uma base de conhecimento para guiar as respostas do nosso agente.
-- MAGIC
-- MAGIC Para isso, utilizaremos o **Vector Search**. Este componente permite comparar as perguntas feitas pelo nosso cliente com as que estão na base de conhecimento e, então, recuperar a resposta correspondente à pergunta com maior similaridade. A única coisa que precisamos fazer é indexar o FAQ, que carregamos mais cedo, no Vector Search!
-- MAGIC
-- MAGIC Vamos lá!

-- COMMAND ----------

-- MAGIC %md ### A. Habilitar o Change Data Feed na tabela `FAQ`
-- MAGIC
-- MAGIC Essa configuração permite com que o Vector Search leia os dados inseridos, excluídos ou alterados no FAQ de forma incremental.

-- COMMAND ----------

ALTER TABLE faq SET TBLPROPERTIES (delta.enableChangeDataFeed = true)

-- COMMAND ----------

-- MAGIC %md ### B. Criar um índice no Vector Search
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Catalog`**
-- MAGIC 2. Busque a sua **tabela** `tutorial.carga.faq`
-- MAGIC 3. Clique em `Create` e depois em `Vector search index`
-- MAGIC 4. Preencha o formulário:
-- MAGIC     - **Nome:** faq_index
-- MAGIC     - **Primary key:** id
-- MAGIC     - **Endpoint**: selecione o endpoint desejado
-- MAGIC     - **Columns to sync:** deixar em branco (sincroniza todas as colunas)
-- MAGIC     - **Embedding source:** Compute embeddings (o Vector Search gerencia a indexação / criação de embeddings)
-- MAGIC     - **Embedding source column:** pergunta
-- MAGIC     - **Embedding model:** databricks-gte-large-en
-- MAGIC     - **Sync computed embeddings:** desabilitado
-- MAGIC     - **Sync mode:** Triggered
-- MAGIC 5. Clique em `Create`
-- MAGIC 6. Aguarde a criação do índice finalizar

-- COMMAND ----------

-- MAGIC %md ### C. Criar a função

-- COMMAND ----------

CREATE OR REPLACE FUNCTION consultar_faq(pergunta STRING)
RETURNS TABLE(id LONG, pergunta STRING, resposta STRING, search_score DOUBLE)
COMMENT 'Use esta função para consultar a base de conhecimento sobre prazos de entrega, pedidos de troca ou devolução, entre outras perguntas frequentes sobre o nosso marketplace'
RETURN select * from vector_search(
  index => 'tutorial.carga.faq_index', 
  query => consultar_faq.pergunta,
  num_results => 1
)

-- COMMAND ----------

-- MAGIC %md ### D. Testar a função

-- COMMAND ----------

SELECT * FROM consultar_faq('Qual o prazo para devolução?')

-- COMMAND ----------

SELECT * FROM consultar_faq('Como emitir a segunda via?')

-- COMMAND ----------

-- MAGIC %md ### E. Testar a função como ferramenta
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Playground`**
-- MAGIC 2. Clique no **seletor de modelos** e selecione o modelo **`Meta Llama 3.1 70B Instruct`** (caso já não esteja selecionado)
-- MAGIC 3. Clique em **Tools** e depois em **Add Tool** 
-- MAGIC 4. Em **Hosted Function**, digite `tutorial.carga.consultar_faq`
-- MAGIC 5. Adicione a instrução abaixo:
-- MAGIC     ```
-- MAGIC     Qual o prazo para devolução?
-- MAGIC     ```
-- MAGIC 6. Clique no ícone **enviar**

-- COMMAND ----------

-- MAGIC %md ## Exercício 03.04 - Fornecendo recomendações personalizadas de produtos com base em suas descrições
-- MAGIC
-- MAGIC Por fim, também gostaríamos de criar uma ferramenta para auxiliar nossos clientes a encontrarem produtos que possuam descrições similares. Essa ferramenta irá auxiliar clientes que estejam insatisfeitos com algum produto e estejam buscando uma troca.
-- MAGIC
-- MAGIC Vamos lá!

-- COMMAND ----------

-- MAGIC %md ### A. Habilitar o Change Data Feed na tabela `produtos`

-- COMMAND ----------

ALTER TABLE produtos SET TBLPROPERTIES (delta.enableChangeDataFeed = true)

-- COMMAND ----------

-- MAGIC %md ### B. Criar um índice no Vector Search
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Catalog`**
-- MAGIC 2. Busque a sua **tabela** `academy.<seu_nome>.produtos`
-- MAGIC 3. Clique em `Create` e depois em `Vector search index`
-- MAGIC 4. Preencha o formulário:
-- MAGIC     - **Nome:** produtos_index
-- MAGIC     - **Primary key:** id
-- MAGIC     - **Endpoint**: selecione o endpoint desejado
-- MAGIC     - **Columns to sync:** deixar em branco (sincroniza todas as colunas)
-- MAGIC     - **Embedding source:** Compute embeddings (o Vector Search gerencia a indexação / criação de embeddings)
-- MAGIC     - **Embedding source column:** descricao
-- MAGIC     - **Embedding model:** databricks-gte-large-en
-- MAGIC     - **Sync computed embeddings:** desabilitado
-- MAGIC     - **Sync mode:** Triggered
-- MAGIC 5. Clique em `Create`
-- MAGIC 6. Aguarde a criação do índice finalizar

-- COMMAND ----------

-- MAGIC %md ### C. Crear la función

-- COMMAND ----------

CREATE OR REPLACE FUNCTION buscar_produtos_semelhantes(descricao STRING)
RETURNS TABLE(id LONG, produto STRING, descricao STRING, search_score DOUBLE)
COMMENT 'Esta função recebe a descrição de um produto, que é utilizada para buscar produtos semelhantes'
RETURN SELECT id, produto, descricao, search_score FROM (
  SELECT *, ROW_NUMBER() OVER (ORDER BY search_score DESC) AS rn
  FROM vector_search(
    index => 'tutorial.carga.produtos_index',
    query => buscar_produtos_semelhantes.descricao,
    num_results => 10)
  WHERE search_score BETWEEN 0.003 AND 0.99
) WHERE rn <= 3

-- COMMAND ----------

-- MAGIC %md ### D. Probar la función

-- COMMAND ----------

SELECT * FROM buscar_produtos_semelhantes('O fone de ouvido DEF é um dispositivo de áudio projetado para fornecer uma experiência de som imersiva e de alta qualidade. Com drivers de alta fidelidade e tecnologia de cancelamento de ruído, ele permite que você se perca na música ou nos detalhes de um podcast sem distrações. Além disso, seu design ergonômico garante confort durante o uso prolongado.')

-- COMMAND ----------

-- MAGIC %md ### E. Probar la función como herramienta
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Playground`**
-- MAGIC 2. Clique no **seletor de modelos** e selecione o modelo **`Meta Llama 3.1 70B Instruct`** (caso já não esteja selecionado)
-- MAGIC 3. Clique em **Tools** e depois em **Add Tool** 
-- MAGIC 4. Em **Hosted Function**, digite `academy.<seu_nome>.buscar_produtos_semelhantes`
-- MAGIC 5. Adicione a instrução abaixo:
-- MAGIC     ```
-- MAGIC     Quais os tablets com boa qualidade da tela?
-- MAGIC     ```
-- MAGIC 6. Clique no ícone **enviar**

-- COMMAND ----------

-- MAGIC %md ## Probando a nuestro agente
-- MAGIC
-- MAGIC 1. No **menu principal** à esquerda, clique em **`Playground`**
-- MAGIC 2. Clique no **seletor de modelos** e selecione o modelo **`Meta Llama 3.1 70B Instruct`** (caso já não esteja selecionado)
-- MAGIC 3. Clique em **Tools** e depois em **Add Tool** 
-- MAGIC 4. Em **Hosted Function**, digite `academy.<seu_nome>.*` para adicionar todas as funções criadas
-- MAGIC 5. Em **System Prompt**, digite: <br>
-- MAGIC `Você é um assistente virtual de um e-commerce. Para responder à perguntas, é necessário que o cliente forneça seu CPF. Caso ainda não tenha essa informação, solicite o CPF educadamente. Você pode responder perguntas sobre entrega, devolução de produtos, status de pedidos, entre outros. Se você não souber como responder a pergunta, diga que você não sabe. Não invente ou especule sobre nada. Sempre que perguntado sobre procedimentos, consulte nossa base de conhecimento.`
-- MAGIC 6. Digite `Olá!`
-- MAGIC 7. Digite `000.000.000-01`
-- MAGIC 8. Digite `Comprei um tablet DEF, porém a qualidade da tela é muito ruim`
-- MAGIC 9. Digite `Poderia recomendar produtos semelhantes?`
-- MAGIC 10. Digite `Como faço para solicitar a troca?`

-- COMMAND ----------

-- MAGIC %md # ¡Felicidades!
-- MAGIC
-- MAGIC ¡Has completado el laboratorio de **Agentes**!
-- MAGIC
-- MAGIC ¡Ahora ya sabes cómo utilizar Foundation Models, Playground y las herramientas de catálogo de Unity para crear prototipos de forma rápida y sencilla de agentes capaces de responder con precisión preguntas complejas!
