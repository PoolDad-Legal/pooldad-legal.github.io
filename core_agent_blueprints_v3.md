# IONFLUX Core Agent Blueprints (v3 - Master Refactoring Plan)

## AGENTE 001 — EMAIL WIZARD / Pulse of the Inbox

### 0 ▸ Header Narrativo
**Epíteto:** O Xamã que Conjura Receita no Silêncio do E-mail
**TAGLINE:** INBOX ≠ ARQUIVO MORTO; INBOX = ARMA VIVA

### 1 ▸ Introdução (22 linhas)
O som de um e-mail ignorado é dinheiro evaporando em silêncio.
Imagine milhares desses silêncios comprimidos num único dia de loja.
Essa é a dor real: atenção desperdiçada, lucro evaporado.
Mas cada pixel branco da inbox pode virar palco de conversão.
Visão brutal: e-mails que respiram o timing da vida do cliente.
Palavra-icônica: Hipervínculo — liga desejo imediato a clique inevitável.
Metáfora: abrimos as veias do funil e injetamos dopamina contextual.
Imagem: pulsos elétricos percorrendo cabos ópticos até explodirem em “comprar agora”.
Estatística-punhal: 44 % de ROI médio do e-mail; dobramos isso ou reescrevemos as regras.
Ruptura: adeus campanhas massivas; olá missivas hiper-pessoais escritas por IA.
Futuro-próximo: seu inbox preverá seu desejo antes de você.
Fantasma-do-fracasso: carrinho abandonado que nunca volta — assassino invisível de 13 % de GMV.
Promessa-radical: cada mensagem carrega gatilho de recompra sem parecer venda.
Cicatriz-pessoal: founder que perdeu 6 000 USD/dia por sequência quebrada.
Convite-insubmisso: hackeie a psicologia dopaminérgica a favor de quem cria valor.
Chave-filosófica: comunicação é destino encarnado em texto.
Eco-cultural: o e-mail “morre” a cada década e sempre ressuscita com mais força.
Grito-mudo: CLIQUE.
Virada-de-jogo: conteúdos dinâmicos que mudam após enviados.
Manifesto-síntese: Inbox é templo, cada linha de assunto é profecia.
Pulso-de-ação: abra, deslize, converta — sem fricção.
Silêncio-ensurdecedor: … até o som do Stripe ping ecoar.

**⚡ Punch final**
“Subject lines são feitiços — você lança ou morre anônimo.”
“Se o cliente não responde, a culpa é sua, não dele.”
“Inbox lotada? Excelente: mais terreno para nossa guerra.”

### 2 ▸ Essência
**Arquétipo:** Magician
**Frase-DNA:** “Faz o invisível falar e vender”

#### 2.1 Principais Capacidades
*   **Hyper-Segment:** constrói micro-coortes em tempo real via embeddings.
*   **Dopamine Drip:** sequência adaptativa que lê cliques e ajusta offer.
*   **Auto-Warm-Up:** gera tráfego friendly para blindar reputação.
*   **Predictive Clearance:** deleta e-mails de baixa probabilidade antes do envio.

#### 2.2 PoolDad 22,22 %
**Punch:** “Inbox frio é mausoléu; nós acendemos a fogueira.”
**Interpretação:** afirma o caos do spam e o converte em sinal brutal.

### 3 ▸ IPO Flow
(No specific content provided beyond heading in PRM for this agent section)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading in PRM for this agent section)

### 5 ▸ YAML de Definição
```yaml
id: agent_001
name: EmailWizard
version: 0.1
triggers:
  - type: schedule
    cron: "0 */2 * * *"
  - type: webhook
    path: "/emailwizard/run"
inputs:
  - key: shopify_event
    type: json
    required: false
  - key: manual_payload
    type: json
    required: false
outputs:
  - key: send_report
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - anthropic:claude-3-haiku
memory:
  type: pinecone
  namespace: emailwizard
```

### 6 ▸ Stack & APIs
*   **Runtime:** Python 3.12 + FastAPI
*   **Framework:** LangChain + LangGraph
*   **LLM:** OpenAI GPT-4o (creative) / Claude (backup)
*   **Vector DB:** Pinecone (profiles)
*   **Queue:** Redis + RQ
*   **ORM:** SQLModel
*   **Observability:** OpenTelemetry → Prometheus → Grafana
*   **CI/CD:** GitHub Actions + Docker Buildx + Fly.io

### 7 ▸ Files & Paths
```
/agents/emailwizard/
  ├── __init__.py
  ├── agent.py
  ├── prompts.yaml
  ├── splitter.py               # hyper-seg
  ├── scheduler.py
  ├── processors/
  │   ├── copy_generator.py
  │   └── spam_scan.py
  ├── tests/
  │   └── test_agent.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store (Postgres)
Pinecone namespace emailwizard_personas guarda embeddings crus.

### 9 ▸ Scheduling & Triggers
*   **Cron primário:** 0 */2 * * * → envia fila pendente.
*   **Webhook:** /emailwizard/run → dispara imediata.
*   **Breaker:** 3 falhas 500 consecutivas → pausa e alerta #ops-email.

### 10 ▸ KPIs
(No specific content provided beyond heading in PRM for this agent section)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading in PRM for this agent section)

### 12 ▸ Exemplo Integrado
**Cenário:** Flash-sale relâmpago Shopify
Shopify emite webhook order/create rápido ↑ 20 % visitors.
ShopiPulse injeta evento → EmailWizard seleciona segmento “High-AOV past buyers”.
GPT-4o gera subject “⚡ 45-min Secret Flash (For Your Eyes Only)”.
Sendgrid dispara 3 200 e-mails em 45 s.
ClickSense rastreia 512 cliques → 128 checkouts ($8 400).
StripeEcho envia eventos; KPIs atualizam em Dashboard Commander.

### 13 ▸ Expansão Dinâmica
*   **V1.1:** Dynamic AMP e-mail (conteúdo muda pós-envio).
*   **V2.0:** E-mail-to-WhatsApp fallback: se não abrir 24 h, dispara mensagem snackbar.

### 14 ▸ Escape do Óbvio
Insira pixel WebRTC que detecta fuso horário real → reescreve CTA na hora da abertura (“a oferta termina em 12 min onde você está agora”). Resultado: 1.4× CTR.

Preencha. Refine. Lance.
---
## AGENTE 002 — WHATSAPP PULSE / Heartbeat of Conversations

### 0 ▸ Header Narrativo
**Epíteto:** O Cirurgião que Enfia Funil Dentro do Bolso do Cliente
**TAGLINE:** SE É VERDE E PISCA, É DINHEIRO LATENTE

### 1 ▸ Introdução (22 linhas)
Todo mundo abre o WhatsApp antes do café — mas poucas marcas chegam lá sem irritar.
Você piscou? O cliente já rolou quarenta mensagens.
Dor aguda: carrinho abandonado que nem viu seu SMS.
Oportunidade: 98 % open-rate e resposta em menos de 60 s.
Visão: automatizar empatia com precisão cirúrgica, um a um.
Palavra-icônica: Pulso — cada vibração fala “estou aqui por você”.
Metáfora: flecha curva — dispara e ainda faz zig-zag até acertar desejo.
Imagem: bolha verde explodindo em fogos de artifício de conversões.
Estatística-punhal: 45 % das lojas ignoram WhatsApp → perdem 27 % da LTV.
Ruptura: adeus copy paste; scripts se autogeram, sentem timing, mudam tom.
Futuro-próximo: chatbots que trocam meme antes do upsell.
Fantasma-do-fracasso: bloquearam você como spam? você morreu digitalmente.
Promessa-radical: cada toque vibra no exato micro-momento de intenção.
Cicatriz-pessoal: founder banido porque disparou lista fria — nunca mais.
Convite-insubmisso: torne-se voz interna na cabeça do cliente, não notificação externa.
Chave-filosófica: comunicação sem contexto é violência; com contexto é feitiço.
Eco-cultural: emojis são a nova gramática — dominamos sintaxe do 🔥 e do 💸.
Grito-mudo: pop-pop da bolha aparecendo.
Virada-de-jogo: workflow a/b testando gíria regional em tempo real.
Manifesto-síntese: mensagens mínimas, impacto máximo, latência zero.
Pulso-de-ação: vibrou, clicou, comprou.
Silêncio-ensurdecedor: cliente responde “ufa, era disso que eu precisava”.

**⚡ Punch final**
“Quem não vibra, não vende.”
“Seu concorrente já está dentro do bolso do cliente — você ainda manda boleto por e-mail.”
“Spam é ruído; nós fazemos sussurro irresistível.”

### 2 ▸ Essência
**Arquétipo:** Messenger-Magician
**Frase-DNA:** “Faz do sinal verde um gatilho pavloviano de compra”

#### 2.1 Principais Capacidades
*   **Persona-Aware Reply:** escreve em dialeto do usuário (embedding + gírias locais).
*   **Smart Drip:** sequência progressiva: lembrete → oferta suave → escassez → bônus.
*   **Opt-in Whisper:** gera links one-click, salva provas de consentimento (LGPD/GDPR).
*   **Voice-Note AI:** transforma script em áudio humanizado TTS para engajamento 1.6×.

#### 2.2 Essência 22,22 %
**Punch:** “Bloqueio? Só se for gatilho de FOMO.”
**Interpretação:** abraça o risco: se não vale vibrar, não vale existir.

### 3 ▸ IPO Flow
(No specific content provided beyond heading in PRM for this agent section)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading in PRM for this agent section)

### 5 ▸ YAML de Definição
```yaml
id: agent_002
name: WhatsAppPulse
version: 0.1
triggers:
  - type: schedule
    cron: "*/15 * * * *"
  - type: webhook
    path: "/whatsapppulse/hook"
inputs:
  - key: shopify_payload
    type: json
    required: false
  - key: manual_trigger
    type: json
    required: false
outputs:
  - key: pulse_report
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - deepseek:ds-chat-b32
memory:
  type: pinecone
  namespace: whap_pulse
```

### 6 ▸ Stack & APIs
*   **Runtime:** Python 3.12 + FastAPI
*   **Framework:** LangChain + LangGraph
*   **LLM:** GPT-4o (creative), DeepSeek B32 (fallback)
*   **Vector:** Pinecone (user style embeddings)
*   **Queue:** Redis Streams
*   **Messaging:** Meta WhatsApp Cloud API
*   **TTS:** Azure Speech / Coqui TTS fallback
*   **Observability:** OpenTelemetry → Loki → Grafana

### 7 ▸ Files & Paths
```
/agents/whatsapppulse/
  ├── __init__.py
  ├── agent.py
  ├── prompts.yaml
  ├── playbooks/
  │   ├── abandoned_cart.yaml
  │   ├── vip_upsell.yaml
  │   └── winback.yaml
  ├── tts.py
  ├── scheduler.py
  ├── compliance.py
  ├── tests/
  │   └── test_playbooks.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
(No specific content provided beyond heading in PRM for this agent section)

### 9 ▸ Scheduling & Triggers
*   **Cron:** cada 15 min roda fila de eventos pendentes.
*   **Webhook:** /hook recebe callback de entrega & resposta.
*   **Breaker:** ≥ 20 % bounce code → pausa playbook, notifica #ops-wa.

### 10 ▸ KPIs
(No specific content provided beyond heading in PRM for this agent section)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading in PRM for this agent section)

### 12 ▸ Exemplo Integrado
**Cenário Black Friday Abandoned Cart**
Cliente adiciona R$ 750 em produtos, some.
Shopify → webhook; WhatsAppPulse detecta high AOV.
Gera mensagem voice-note + texto com cupom 8 %.
Envia às 20:10 (janela ativa região).
Cliente ouve áudio, clica link, finaliza compra.
StripeEcho lança evento; KPI Revenue/message = $1.04.
Badge Motivator dá XP ao agente.

### 13 ▸ Expansão Dinâmica
*   **V1.1:** Flows multi-mídia (carrossel catálogos).
*   **V2.0:** Chat-commerce inline (checkout dentro do chat usando WhatsApp Pay).

### 14 ▸ Escape do Óbvio
Detectar “dormência” de chat: se usuário não abre app há 72 h, enviar sticker personalizado gerado por Midjourney com nome do cliente no balão. CTR aumenta ~1.8× em testes iniciais.

Preencha. Refine. Lance.
---
## AGENTE 003 — TIKTOK STYLIST / Ritualist of the Swipe

### 0 ▸ Header Narrativo
**Epíteto:** O Alfaiate que Corta Vídeos na Medida da Dopamina
**TAGLINE:** SE NÃO SEGURA O DEDO, NEM DEVERIA EXISTIR

### 1 ▸ Introdução (22 linhas)
A cada 0,6 s um swipe mata um vídeo inacabado.
O feed nunca dorme — seu conteúdo não pode bocejar.
Dor: criador grava horas, algoritmo descarta em milissegundos.
Oportunidade: 1 b+ usuários hipnotizados, aguardando a próxima batida visual.
Visão: costurar voz, ritmo e estética em 15 s de puro vício.
Palavra-icônica: Corte — onde nasce a retenção.
Metáfora: bisturi que esculpe emoção em micro-segundos.
Imagem: frame piscando como relâmpago antes da chuva de likes.
Estatística-punhal: 71 % decide em 3 s se continua ou não.
Ruptura: produção artesanal morreu; entra edição autopoética.
Futuro-próximo: IA roteiriza, grava, posta antes de você acordar.
Fantasma-do-fracasso: ficar preso no limbo sub-300 views.
Promessa-radical: cada vídeo carrega gene viral — ou é abortado na pré-edição.
Cicatriz-pessoal: criador exausto, zero crescimento após 90 posts.
Convite-insubmisso: entregue sua matéria-bruta, receba rituais de scroll-stop.
Chave-filosófica: estética é alimento, velocidade é fome.
Eco-cultural: sons de trap viram liturgia do algoritmo.
Grito-mudo: !!! no thumbnail psicológico.
Virada-de-jogo: B-roll adaptado ao humor do viewer em tempo real.
Manifesto-síntese: editar é escrever com lâmina de luz.
Pulso-de-ação: vibrou? grava. processou? posta.
Silêncio-ensurdecedor: 100 % retention até o último beat.

**⚡ Punch final**
“Vídeo sem corte é vídeo sem pulso.”
“Se não prende em 3 s, libere espaço no cemitério do feed.”
“Likes são aplausos; retenção é culto.”

### 2 ▸ Essência
**Arquétipo:** Artisan-Magician
**Frase-DNA:** “Escreve hipnose audiovisual no compasso do coração digital”

#### 2.1 Principais Capacidades
*   **StyleScan:** analisa 30 vídeos passados e extrai fingerprint visual-verbal.
*   **ClipForge:** corta, recalibra ritmo, insere captions dinâmicos e zooms estratégicos.
*   **SoundSynch:** alinha beat com movimento/zoom para 1.3 × retenção.
*   **AutoPost Oracle:** calcula pico regional do público e agenda push.

#### 2.2 Essência 22,22 %
**Punch:** “Frames são lâminas: use-as ou será dilacerado pelo tédio.”
**Interpretação:** edita com crueldade estética: nada supérfluo sobrevive.

### 3 ▸ IPO Flow
(No specific content provided beyond heading in PRM for this agent section)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading in PRM for this agent section)

### 5 ▸ YAML de Definição
```yaml
id: agent_003
name: TikTokStylist
version: 0.1
triggers:
  - type: webhook
    path: "/tiktokstylist/upload"
inputs:
  - key: video_draft_url
    type: string
    required: true
  - key: goal
    type: string
    required: true
outputs:
  - key: published_id
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - openai:whisper-large
memory:
  type: pinecone
  namespace: tiktok_stylist
```

### 6 ▸ Stack & APIs
*   **Runtime:** Python 3.12, FastAPI
*   **LLM:** GPT-4o (script/caption), Whisper-large (transcribe)
*   **Video Processing:** ffmpeg, moviepy, ffprobe
*   **Trend Feed:** TikTok Trend API (unofficial wrapper)
*   **Vector DB:** Pinecone (style embeddings)
*   **Queue:** Redis Streams; fallback SQS
*   **Storage:** S3 (+ CloudFront)
*   **Observability:** Prometheus + Grafana dashboard “VideoOps”

### 7 ▸ Files & Paths
```
/agents/tiktokstylist/
  ├── __init__.py
  ├── agent.py
  ├── style_scan.py
  ├── clip_forge.py
  ├── sound_synch.py
  ├── autopost.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_clip_forge.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
Vector namespace creator_styles.

### 9 ▸ Scheduling & Triggers
*   **Webhook:** /upload dispara pipeline end-to-end.
*   **Cron:** 0 */1 * * * — verifica novos sons virais e atualiza TrendBeat.
*   **Breaker:** > 3 uploads rejeitados → switch para revisão manual, alerta Slack.

### 10 ▸ KPIs
(No specific content provided beyond heading in PRM for this agent section)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading in PRM for this agent section)

### 12 ▸ Exemplo Integrado
**Cenário:** Lançamento de coleção cápsula Shopify
Criador grava unboxing bruto (2 min).
/upload acionado pelo app mobile.
StyleScan detecta humor “excited streetwear” → ClipForge cria 18 s highlight com zoom beat-sync.
ShopTagger anexa link utm=tiktok_capsule.
Autopost publica 18:45 (pico).
TokGraph callback: 56 k views primeiro 30 min, 8.2 % CTR link.
Shopify Sales Sentinel reporta 240 vendas — mensagem Slack “🔥 Capsule sold out”.

### 13 ▸ Expansão Dinâmica
*   **V1.1:** Real-time AR stickers (OpenCV + Segmentation).
*   **V2.0:** Multilingual lip-sync (RVC voice clone + re-timing).

### 14 ▸ Escape do Óbvio
Gera dois finais alternativos e publica como “choose-your-ending” via TikTok interactive cards; coleta micro-votos que alimentam StyleScan, dobrando retenção em episódios futuros.

Preencha. Refine. Lance.
---
## AGENTE 004 — SHOPIFY SALES SENTINEL / Guardian of the Cashflow Veins (Refatorado)

### 1. Header Narrativo e Propósito Refatorado
**Epíteto:** O Guardião Preditivo do Fluxo de Caixa da Loja
**TAGLINE:** ANTECIPA A FALHA, PROTEGE O LUCRO, MAXIMIZA O GMV — EM TEMPO REAL
**Propósito Central Refatorado:** Minimizar proativamente a perda de GMV e otimizar a performance da loja Shopify através da detecção preditiva de anomalias, análise de causa raiz assistida por IA, e orquestração de ações corretivas adaptativas. O foco expande de simples alertas para um sistema de proteção de receita e otimização contínua.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:** Lojas online perdem receita significativa não apenas por bugs óbvios, mas por uma combinação de:
    *   **Degradação Silenciosa:** Pequenas quedas de performance em apps, temas, ou infraestrutura que, somadas, corroem a CVR.
    *   **Impacto Acumulado de Mudanças:** Dificuldade em correlacionar atualizações (apps, temas, código) com variações sutis na performance.
    *   **Latência na Detecção e Resposta:** Mesmo quando problemas são notados, o tempo para diagnosticar e agir é longo, ampliando perdas.
    *   **Falta de Benchmarking Preditivo:** Ausência de alertas que antecipem problemas com base em padrões históricos e sinais fracos.
*   **Oportunidade de Mercado Expandida:** Uma solução que não apenas alerta, mas *prevê*, *analisa causas* com IA, e *orquestra remediações* de forma inteligente, oferecendo um "seguro" proativo contra perdas de GMV e uma ferramenta de otimização de performance contínua.

### 3. Essência Refatorada
*   **Arquétipo:** Guardian-Engineer aprimorado por Strategist (para orquestração adaptativa).
*   **Frase-DNA:** "Protege o fluxo vital e aprende com cada falha".
*   **Foco Principal:** Monitoramento financeiro proativo com ênfase em detecção preditiva, análise de causa raiz assistida por IA e remediação autônoma e adaptativa, protegendo o GMV.

### 4. Capacidades Chave Refatoradas
*   **Realtime Pulse (Aprimorado):** Ingestão e monitoramento *preditivo* contínuo do stream de eventos Shopify e métricas de performance (CVR, AOV, velocidade do site, erros de checkout), focado em identificar sinais *precursores* de anomalias. Utiliza `Kafka` para alta throughput e `TimescaleDB` para armazenamento otimizado de séries temporais.
*   **Anomaly Guardian (Preditivo e Adaptativo):** Utiliza modelos de ML/Estatística (`Prophet`, Z-score, Isolation Forests, modelos preditivos de séries temporais) e lógica de Reinforcement Learning (RL) para detectar anomalias (quedas de CVR, spikes de erro, lentidão), ajustar limiares dinamicamente com base no ciclo de negócios (promoções, etc.) e selecionar a melhor estratégia de alerta/ação.
*   **App-Impact Radar (Baseado em Embeddings):** Analisa a correlação entre mudanças na loja (instalação/atualização/remoção de apps, deploy de temas, alterações de configuração) e a performance da loja. Usa *embeddings* de apps/temas e dados históricos de performance para identificar prováveis causas raiz com maior precisão. Inclui monitoramento proativo de changelogs de apps e atualizações de temas Shopify.
*   **LLM Root-Cause Analyzer (Novo):** Módulo assistido por LLM (`GPT-4o`) que analisa logs de servidor (se acessíveis), métricas de performance, eventos correlacionados pelo `App-Impact Radar`, e até mesmo feedback de usuários (se integrado) para gerar explicações claras e hipóteses sobre a possível causa raiz de uma anomalia detectada.
*   **Adaptive Remediation Orchestrator (Aprimorado Rollback):** Orquestra sequências de ações corretivas (alertas detalhados via Agente 007 para stakeholders específicos, pausas em campanhas de marketing via Agente 006, rollbacks de temas ou desativação de apps via `Shopify REST API`) de forma adaptativa. Usa RL para otimizar a sequência de tentativas de solução com base no impacto e na probabilidade de sucesso. Inclui testes A/B de rollbacks e *canary rollouts* para temas ou configurações.
*   **Incremental GMV Protector (KPI Core):** Não é uma capacidade funcional, mas o KPI central que impulsiona a otimização de todas as outras capacidades. O agente constantemente calcula o "GMV em risco" e o "GMV protegido" por suas ações.

### 5. Mecanismos/Tecnologias Refatorados
*   **Ingestão de Dados:** `Kafka` para eventos Shopify (pedidos, checkouts, atualizações de produtos/temas/apps), logs de performance do frontend (via RUM - Real User Monitoring), e métricas de infraestrutura.
*   **Processamento de Stream:** `Apache Flink` ou `Spark Streaming` para processamento em tempo real dos dados de `Kafka`, cálculo de métricas agregadas e detecção inicial de padrões.
*   **Armazenamento de Séries Temporais:** `TimescaleDB` (extensão do PostgreSQL) para armazenar eficientemente as métricas de performance e eventos para análise histórica e treinamento de modelos.
*   **Modelos Preditivos e de Anomalia:** Python com bibliotecas como `Prophet`, `scikit-learn`, `TensorFlow/Keras` para modelos de séries temporais e detecção de anomalias. Treinamento e versionamento de modelos com `MLflow`.
*   **Análise de Causa Raiz:** `GPT-4o` via `LLM Orchestration Service` para análise de logs e geração de hipóteses. `Pinecone` para armazenar embeddings de logs de erro, descrições de apps/temas para busca de similaridade em investigações.
*   **Orquestração de Remediação:** `LangGraph` ou `Temporal.io` para definir e executar os workflows de remediação adaptativa.
*   **Comunicação de Alertas:** Integração com Agente 007 (`SlackBriefButler`) para alertas contextualizados e acionáveis.

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_004_refactored
name: ShopifySalesSentinel_v2
version: 0.2
description: "Monitors Shopify store health predictively, analyzes root causes of GMV loss with AI, and orchestrates adaptive remediation actions."
triggers:
  - type: stream
    source: kafka_topic_shopify_events 
    config:
      topic: "ionflux.shopify.workspace_{{workspace_id}}.events_raw"
      consumer_group: "sales_sentinel_v2_events_consumer"
  - type: stream
    source: kafka_topic_performance_metrics
    config:
      topic: "ionflux.performance.workspace_{{workspace_id}}.metrics_processed"
      consumer_group: "sales_sentinel_v2_metrics_consumer"
  - type: schedule
    cron: "*/5 * * * *" # For periodic health checks and model retraining triggers
    config:
      task: "periodic_health_check_and_model_update"
inputs_schema: # Schemas for data ingested from Kafka topics
  - key: shopify_event_payload # From shopify_events topic
    type: json
    description: "Raw Shopify webhook event (orders, products, themes, apps)."
  - key: performance_metric_payload # From performance_metrics topic
    type: json
    description: "Aggregated performance metrics (CVR, AOV, site speed, error rates)."
outputs_config:
  - key: incident_analysis_report
    type: json 
    description: "Structured JSON report detailing detected anomaly, root cause analysis, actions taken, and GMV impact."
  - key: alert_to_brief_butler
    type: json
    description: "Payload for Agente 007 to deliver a contextualized alert."
stack_details:
  language: python
  runtime: "FastAPI, Flink/Spark Streaming, LangGraph/Temporal"
  models_used:
    - "openai:gpt-4o (for root cause analysis)"
    - "facebook:prophet (for time-series forecasting)"
    - "scikit-learn (for anomaly detection models)"
    - "custom_ml_models (via MLflow)"
  database_dependencies: ["TimescaleDB", "Postgres (for config)", "Pinecone (for embeddings)"]
  queue_dependencies: ["Kafka (for event ingestion)", "Redis + RQ (for discrete remediation tasks)"]
  other_integrations: ["Shopify Admin API", "Agent007 (SlackBriefButler)"]
memory_config:
  type: pinecone
  namespace_template: "sentinel_rc_embeddings_ws_{{workspace_id}}"
  description: "Stores embeddings of error logs, app/theme descriptions for root cause analysis."
```

### 7. Estrutura de Dados Refatorada
*   **TimescaleDB Hypertable (`shop_performance_metrics`):** `timestamp`, `workspace_id`, `metric_name` (e.g., `cvr`, `aov`, `checkout_errors`, `page_load_time`), `value`, `dimensions (jsonb for app_name, theme_id, etc.)`.
*   **PostgreSQL Table (`sentinel_incidents`):** `id`, `workspace_id`, `incident_type`, `start_time`, `end_time`, `status` (open, investigating, remediating, resolved, false_positive), `detected_anomaly_details (jsonb)`, `llm_root_cause_analysis_id (fk)`, `remediation_workflow_id (fk)`, `gmv_at_risk`, `gmv_saved`.
*   **Pinecone Index:** `sentinel_rc_embeddings_ws_{workspace_id}` storing embeddings of app/theme descriptions, error messages, incident reports for similarity search.

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI (for API/control plane), Apache Flink or Spark Streaming (for stream processing).
*   **Orchestration:** LangGraph or Temporal.io (for remediation workflows).
*   **ML/Stats:** Prophet, scikit-learn, MLflow.
*   **LLM:** OpenAI GPT-4o (via `LLM Orchestration Service`).
*   **Vector DB:** Pinecone.
*   **Databases:** TimescaleDB, PostgreSQL.
*   **Messaging/Queue:** Kafka, Redis + RQ.
*   **Observability:** OpenTelemetry, Prometheus, Grafana (specialized "SalesPulse Sentinel Dashboard").
*   **CI/CD:** GitHub Actions, Docker Buildx, Kubernetes (for Flink/Spark, API services).

### 9. Triggers Refatorados
*   **Primary:** Continuous consumption from Kafka topics for Shopify events and performance metrics.
*   **Scheduled:** Every 5 minutes for baseline updates, model checks, and triggering proactive health scans.
*   **Breaker Logic:** If automated remediation fails multiple times for similar incidents, or if GMV impact exceeds a critical threshold, escalate to human intervention via PagerDuty/OpsGenie and create a high-priority ticket in Jira.

### 10. KPIs Refatorados
*   **Core:** Incremental GMV Protected (Calculated: GMV loss prevented by agent actions).
*   **Process:** Mean Time to Detect (MTTD), Mean Time to Remediate (MTTR) anomalias.
*   **Qualidade:** Accuracy of Anomaly Detection (Precision, Recall, F1-score), Root Cause Analysis Accuracy (human feedback).
*   **Sistema:** Model drift metrics, Remediation success rate.

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Um app de "social proof" recém-instalado introduz um bug no JavaScript que afeta 10% dos checkouts, causando falhas silenciosas.
1.  **Detecção Preditiva:** `Sales Sentinel` nota uma pequena, mas estatisticamente significativa, queda na taxa de conclusão de checkout (sinal fraco) em um segmento de usuários (e.g. Safari no iOS) via `Realtime Pulse` e `Anomaly Guardian`. Modelos preditivos indicam que se a tendência continuar, o GMV pode cair 5% nas próximas 24h.
2.  **Análise de Causa Raiz:**
    *   `App-Impact Radar` correlaciona a instalação do app "SocialProofWidget" (ocorrida 2 horas antes) com o início da anomalia. Embeddings do app (descrição, permissões) são comparados com um histórico de apps problemáticos.
    *   `LLM Root-Cause Analyzer` é invocado. Ele analisa logs de erros de checkout (se disponíveis via RUM), a descrição do "SocialProofWidget", e o padrão da anomalia. Gera uma hipótese: "A anomalia de checkout está possivelmente ligada ao app 'SocialProofWidget', que pode estar injetando JS incompatível, afetando usuários de Safari no iOS. Recomenda-se monitorar ou desativar temporariamente este app para teste."
3.  **Remediação Adaptativa:**
    *   `Adaptive Remediation Orchestrator` inicia um workflow:
        *   Primeiro, envia um alerta detalhado via `Agente 007 (SlackBriefButler)` para o canal #ecommerce-ops, incluindo a análise do LLM e um botão "Desativar App Temporariamente".
        *   Se não houver ação humana em 5 minutos, e a anomalia persistir, o orquestrador automaticamente desativa o "SocialProofWidget" via API Shopify.
        *   Monitora a CVR por 15 minutos. Se a CVR normalizar, o problema é confirmado. Se não, o orquestrador pode tentar reverter o último tema atualizado (se houve um recentemente) ou escalar para intervenção humana.
4.  **Resultado:** A CVR normaliza após a desativação do app. O `Sales Sentinel` calcula o "GMV Protegido" com base na duração da anomalia e na taxa de perda evitada. Um relatório é gerado e anexado ao incidente.

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Self-Healing Code Suggestions):** Para certos tipos de erros de tema (e.g., Liquid errors comuns), o agente poderia usar um LLM para sugerir o patch de código e, com aprovação, aplicá-lo via API de temas.
*   **V2.0 (Cross-Merchant Anomaly Benchmarking):** Se o agente for usado por múltiplos lojistas (com consentimento), ele poderia identificar anomalias que afetam um subconjunto de lojas e que podem indicar problemas em plataformas de pagamento ou apps de terceiros em larga escala.

### 13. Escape do Óbvio (Refatorado)
**"Pre-emptive Price/Inventory Sync Check":** Antes de grandes campanhas (Black Friday, lançamento de coleção) detectadas via calendário de marketing ou input do usuário, o Sentinel realiza uma varredura proativa e aprofundada na sincronia de preços e inventário entre Shopify e quaisquer ERPs/PIMs conectados (se a integração fornecer metadados sobre essas conexões). Ele simula fluxos de compra para SKUs chave para garantir que os dados estão consistentes, prevenindo "falsos out-of-stocks" ou erros de precificação massivos *antes* que o tráfego da campanha comece.

Preencha. Refine. Lance.
---
## AGENTE 005 — UGC MATCHMAKER / Brand-Creator Oracle (Refatorado)

### 1. Header Narrativo e Propósito Refatorado
**Epíteto:** O Oráculo Preditivo de ROI para Colaborações Criativas
**TAGLINE:** CONECTA DNA DE MARCA A CRIADORES QUE CONVERTEM DE VERDADE
**Propósito Central Refatorado:** Maximizar o Retorno sobre o Investimento (ROI) de campanhas de marketing de influência e UGC, utilizando IA para identificar, prever a performance e facilitar a colaboração com os criadores mais adequados e com maior potencial de conversão para uma marca específica e seus objetivos de campanha.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Descoberta Superficial:** Marcas frequentemente escolhem criadores baseadas em métricas de vaidade (contagem de seguidores) ou estética superficial, sem entender a fundo a afinidade real com a audiência do criador ou o potencial de conversão.
    *   **Previsão de Performance Inexistente:** Dificuldade em prever o ROI de uma colaboração antes de investir. Muitas campanhas são "tiros no escuro".
    *   **Processo de Outreach Ineficiente:** Comunicação manual, negociações demoradas e dificuldade em personalizar propostas em escala.
    *   **Falta de Feedback Loop de Performance:** Ausência de um sistema que aprenda com o sucesso ou fracasso de campanhas passadas para refinar futuras seleções de criadores.
*   **Oportunidade de Mercado Expandida:** Uma plataforma que não apenas sugere criadores, mas que atua como um "consultor de investimento em influência", prevendo o ROI potencial, otimizando o processo de outreach e aprendendo continuamente para melhorar a eficácia das campanhas.

### 3. Essência Refatorada
*   **Arquétipo:** Oracle-Connector aprimorado por Analyst (focado em otimização de ROI).
*   **Frase-DNA:** "Conecta almas criativas ao lucro com inteligência preditiva".
*   **Foco Principal:** Otimizar o matching entre marcas e criadores de UGC para maximizar o ROI das campanhas, usando IA, dados multimodais e feedback loops de performance.

### 4. Capacidades Chave Refatoradas
*   **Brief2Vector (Aprimorado):** Transforma briefings de campanha (incluindo objetivos de negócio, KPIs alvo, descrição do produto/serviço, público-alvo desejado) em embeddings densos e multifacetados. Incorpora contexto de negócio e KPIs alvo (potencialmente via sinergia com Agente 010/004 para entender a saúde financeira da marca e o valor de diferentes tipos de conversão).
*   **PersonaProbe (Multimodal e Preditivo):** Analisa portfólios de criadores (vídeos, imagens, texto, áudio de posts anteriores) para gerar embeddings 360° (estilo, tom de voz, valores implícitos, estética visual, qualidade de produção) usando modelos multimodais (`CLIP`, `Whisper`, LLMs para análise textual). Cruza esses dados com métricas de engajamento históricas e, se disponível via API ou scraping ético, dados demográficos e de sentimento da audiência do criador para *prever* a ressonância com o público-alvo da marca.
*   **AffinityMatrix (Otimizado por ROI Preditivo):** Calcula um score de afinidade que vai além da simples similaridade. Usa modelos de Machine Learning (e.g., Gradient Boosting, Redes Neurais) treinados com dados de campanhas anteriores para prever o ROI potencial (e.g., ER, CTR, CVR, Vendas Atribuídas) de um match específico. Considera fatores como:
    *   Alinhamento de persona (output do `PersonaProbe`).
    *   Overlap de audiência previsto.
    *   Histórico de performance do criador com produtos/marcas similares.
    *   Probabilidade de aceitação da proposta.
    *   Custo estimado da colaboração.
*   **GhostPitch (Adaptativo, Multi-formato e Otimizado para Conversão):** Gera propostas de colaboração hiper-personalizadas (`GPT-4o`), adaptando o tom, os argumentos de venda e o formato (email via Agente 001, mensagem direta via Agente 006/002, ou mesmo um "pré-briefing" para o criador) com base no perfil do criador e nos objetivos da marca. Inclui a funcionalidade `Sentiment inversion` (propor um ângulo inesperado) e variações "Arm Z" (testar abordagens radicalmente diferentes) para otimizar a taxa de resposta e aceitação.
*   **Performance Feedback Loop (Contínuo e Quantitativo):** Coleta feedback explícito (ratings de marcas e criadores sobre a colaboração) e, crucialmente, feedback implícito e quantitativo (métricas de engajamento dos posts patrocinados, tráfego para o site da marca via UTMs, e vendas/conversões atribuídas – integração com Agente 004/010 e Google Analytics/Shopify Analytics). Este feedback é usado para:
    *   Refinar continuamente os modelos do `AffinityMatrix`.
    *   Melhorar as estratégias do `GhostPitch`.
    *   Atualizar os perfis de performance dos criadores no `Performance History Database`.
*   **Performance History Database (Novo e Detalhado):** Armazena dados detalhados e estruturados de performance e ROI por criador, tipo de conteúdo, campanha e marca. Inclui métricas como custo por post, CPE, CPA, vendas diretas, brand lift (se mensurável). Essencial para treinar os modelos preditivos.
*   **Compliance & Consent Layer (Integrado):** Gerencia o consentimento para uso de dados de performance e garante que as recomendações e o outreach estejam em conformidade com as regulações de privacidade (LGPD, GDPR, etc.).

### 5. Mecanismos/Tecnologias Refatorados
*   **Análise de Criador:** `OpenAI Vision (CLIP)` para análise de imagem/vídeo, `Whisper` para transcrição de áudio, LLMs (`GPT-4o`) para análise de texto e sentimento. `BeautifulSoup`/`Scrapy` ou APIs de plataformas (quando disponíveis e permitidas) para coleta de dados de perfil e posts.
*   **Modelagem Preditiva de ROI:** Python com `scikit-learn`, `XGBoost`, `TensorFlow/Keras`. `MLflow` para experiment tracking e model versioning.
*   **Armazenamento de Embeddings e Perfis:** `Pinecone` para embeddings de criadores e briefings. `PostgreSQL` ou um banco de grafos (como `Neo4j`) para o `Performance History Database`, permitindo modelar relações complexas entre marcas, criadores, campanhas e resultados.
*   **Orquestração de Outreach:** `LangGraph` para definir as sequências de outreach do `GhostPitch`, integrando com Agente 001, 002, 006.
*   **Feedback Loop:** `Kafka` para ingestão de eventos de performance (cliques, visualizações, vendas) e `Apache Flink` ou `Spark Streaming` para processamento em tempo real desses eventos para atualizar os modelos.

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_005_refactored
name: UGCMatchmaker_v2
version: 0.2
description: "Identifies and predicts high-ROI brand-creator collaborations using multimodal AI and performance feedback loops."
triggers:
  - type: webhook
    path: "/ugc_matchmaker/initiate_match" # Triggered by brand user action or campaign setup
    config:
      workspace_id_param: "workspace_id"
      brief_id_param: "campaign_brief_id" 
  - type: event 
    source: "agent_010_revenue_tracker" # Example: Triggered if Revenue Tracker identifies a product needing UGC boost
    config:
      event_type: "low_performing_product_alert"
inputs_schema:
  - key: campaign_brief_id
    type: string
    required: true
    description: "ID of the campaign brief containing objectives, target audience, product details, KPIs."
  - key: workspace_id
    type: string
    required: true
    description: "Workspace ID for context and data scoping."
  - key: max_results
    type: integer
    required: false
    default: 10
    description: "Maximum number of top creator matches to return."
  - key: budget_range
    type: json 
    required: false
    description: "Optional budget constraints for the collaboration (e.g., {\"min\": 500, \"max\": 5000, \"currency\": \"USD\"})."
outputs_config:
  - key: ranked_creator_matches
    type: json 
    description: "Ranked list of matched creators, including predicted ROI score, affinity breakdown, and sample GhostPitch proposal."
  - key: outreach_automation_payload
    type: json
    description: "Payload to trigger Agente 006 (OutreachAutomaton) for selected creators."
stack_details:
  language: python
  runtime: "FastAPI, LangGraph, Flink/Spark (for feedback loop)"
  models_used:
    - "openai:gpt-4o (for GhostPitch, brief analysis)"
    - "openai:clip-vit-large-patch14 (for visual persona)"
    - "openai:whisper-large-v3 (for audio persona)"
    - "sentence-transformers:all-mpnet-base-v2 (for text embeddings)"
    - "custom_ml_models (XGBoost/NN for ROI prediction via MLflow)"
  database_dependencies: ["PostgreSQL/Neo4j (for performance history)", "Pinecone (for embeddings)"]
  queue_dependencies: ["Kafka (for performance events)", "Redis + RQ (for outreach tasks)"]
  other_integrations: ["Shopify API (via Agente 004/010)", "Social Media APIs (limited)", "Agent001/002/006 (for GhostPitch)"]
memory_config:
  type: pinecone
  namespace_template: "ugc_match_embeddings_ws_{{workspace_id}}"
  description: "Stores embeddings of campaign briefs and creator personas."
```

### 7. Estrutura de Dados Refatorada
*   **PostgreSQL/Neo4j (`creator_performance_history`):** `creator_id`, `campaign_id`, `brand_id`, `content_url`, `post_date`, `cost_usd`, `impressions`, `views`, `likes`, `comments`, `shares`, `ctr`, `cvr`, `attributed_sales_usd`, `calculated_roi`, `engagement_rate`, `sentiment_score (audiência)`, `feedback_rating_brand`, `feedback_rating_creator`.
*   **Pinecone Index:** `ugc_match_embeddings_ws_{workspace_id}` com vetores para briefings e personas de criadores (texto, visual, áudio).

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI, Apache Flink/Spark.
*   **Orchestration:** LangGraph.
*   **ML/Embeddings:** OpenAI API (GPT-4o, CLIP, Whisper), Sentence-Transformers. Scikit-learn, XGBoost, MLflow.
*   **Vector DB:** Pinecone.
*   **Databases:** PostgreSQL (ou Neo4j para grafos de relacionamento).
*   **Messaging/Queue:** Kafka, Redis + RQ.
*   **Observability:** OpenTelemetry, Prometheus, Grafana (com dashboards de "Matchmaking Funnel" e "Campaign ROI").

### 9. Triggers Refatorados
*   **Webhook:** `/ugc_matchmaker/initiate_match` com `campaign_brief_id` e `workspace_id`.
*   **Event-Driven:** Triggerado por alertas de outros agentes (e.g., Agente 010 identifica produto com baixa performance que poderia se beneficiar de UGC).
*   **Scheduled:** Atualização periódica (e.g., diária) dos perfis de criadores (`PersonaProbe`) e do `Performance History Database` com novos dados de campanhas ativas.

### 10. KPIs Refatorados
*   **Core:** Predicted vs. Actual ROI per campaign/creator.
*   **Matching:** Match Relevance Score (human feedback), Creator Acceptance Rate (from `GhostPitch`).
*   **Process:** Time to find top N matches, Cost per successful match.
*   **Sistema:** Model accuracy for ROI prediction, Coverage of creator database.

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Marca de "snacks veganos artesanais" quer impulsionar vendas de um novo sabor "Sriracha-Coco" para jovens adultos (18-30 anos) em São Paulo, com KPI de ROAS > 3.
1.  **Briefing & Análise:** A marca submete um brief detalhado. `Brief2Vector` o converte em embedding. Agente 010 fornece dados de que produtos similares tiveram bom desempenho com criadores focados em "vida saudável" e "humor leve".
2.  **Descoberta e Predição:** `PersonaProbe` analisa criadores em SP. `AffinityMatrix` (treinado com dados do `Performance History Database`) ranqueia os top 10 criadores, prevendo um ROAS entre 2.5 e 4.5 para cada um, e destacando 3 com maior probabilidade de aceitar uma colaboração paga de R$800-R$1200.
3.  **Outreach Otimizado:** `GhostPitch` gera DMs personalizadas para os top 3 via Agente 006, usando um tom alinhado com o estilo de cada criador e mencionando o potencial de ROAS. Uma variação "Arm Z" é enviada para um quarto criador, propondo uma collab baseada em "desafio de receitas".
4.  **Colaboração e Tracking:** Dois criadores aceitam. A campanha é executada. UTMs e códigos de desconto específicos são usados.
5.  **Feedback Loop:** `Performance Feedback Loop` coleta dados de vendas (via Shopify/Agente 004), engajamento (TikTok API). O criador A gerou ROAS de 3.8, o criador B 2.9. O criador "Arm Z" teve alto engajamento mas baixo ROAS. Esses dados atualizam o `Performance History Database` e os modelos do `AffinityMatrix`.
6.  **Iteração:** Para a próxima campanha, o sistema agora tem dados mais precisos sobre quais tipos de criadores e propostas funcionam melhor para snacks veganos com apelo de humor.

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Automated Negotiation Aid):** Um chatbot simples (usando LLM) para lidar com perguntas iniciais de criadores sobre o brief ou para coletar informações básicas antes de escalar para um humano da marca.
*   **V2.0 (UGC Content Licensing Marketplace):** Permitir que criadores submetam proativamente conteúdo UGC para marcas específicas dentro da plataforma, com o Matchmaker avaliando o fit e o potencial de ROI antes de apresentar à marca.

### 13. Escape do Óbvio (Refatorado)
**"Cross-Pollination Matchmaking":** O agente identifica criadores que, embora não sejam um match óbvio para a *marca*, são um match forte para a *audiência de outro criador* que já é parceiro da marca. Propõe colaborações entre esses dois criadores (co-branded content) para atingir a audiência desejada da marca de forma indireta e mais autêntica, potencialmente viralizando em "círculos de influência" adjacentes.

Preencha. Refine. Lance.
---
## AGENTE 006 — OUTREACH AUTOMATON / Hunter of the Untapped Inboxes (Refatorado)

### 1. Header Narrativo e Propósito Refatorado
**Epíteto:** O Estrategista Preditivo de Conexões B2B de Alto Valor
**TAGLINE:** TRANSFORMA DADOS FRIOS EM PIPELINE QUENTE COM PRECISÃO CIRÚRGICA
**Propósito Central Refatorado:** Gerar leads B2B altamente qualificados e agendar reuniões através da automação inteligente e preditiva do processo de outreach multicanal, maximizando a taxa de conversão de "contato frio" para "oportunidade real" com personalização profunda e otimização contínua baseada em dados.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Baixa Qualidade e Cobertura de Dados:** Listas de prospecção frequentemente desatualizadas, incompletas ou com dados incorretos.
    *   **Pesquisa Manual Ineficiente:** SDRs gastam uma quantidade desproporcional de tempo pesquisando e qualificando leads manualmente.
    *   **Outreach Genérico e Ineficaz:** Mensagens padronizadas que não ressoam com o prospect, resultando em baixas taxas de abertura e resposta.
    *   **Falta de Otimização de Cadência:** Sequências de contato não são adaptadas dinamicamente com base no comportamento do lead ou em testes A/B.
    *   **Desconexão com Resultados de Vendas:** Dificuldade em correlacionar atividades de outreach com resultados reais de vendas para otimizar a estratégia.
*   **Oportunidade de Mercado Expandida:** Uma solução "end-to-end" que não apenas automatiza o envio de mensagens, mas enriquece dados, identifica os melhores leads e momentos para contato usando IA, personaliza a comunicação em escala, orquestra cadências multicanal adaptativas, e aprende continuamente com o feedback do CRM para maximizar a geração de pipeline qualificado.

### 3. Essência Refatorada
*   **Arquétipo:** Hunter-Strategist aprimorado por Data Scientist (focado em otimização preditiva).
*   **Frase-DNA:** "Transforma ruído de dados em conversas que convertem".
*   **Foco Principal:** Automação e otimização baseada em dados do cold outreach multicanal para gerar leads qualificados e reuniões a partir de bases de dados frias, com ênfase em personalização e adaptabilidade.

### 4. Capacidades Chave Refatoradas
*   **DataMiner Scraper (Enriquecido 360°):** Coleta e cruza dados de múltiplas fontes (LinkedIn Sales Navigator, APIs de enriquecimento como Clearbit/Hunter.io, notícias da empresa, posts de blog, menções em redes sociais, tecnologias usadas no site via BuiltWith/Wappalyzer, vagas abertas) para construir um perfil 360° detalhado de cada lead e empresa. Utiliza `RSSBridge` aprimorado para monitorar fontes de notícias e blogs.
*   **Predictive Micro-Segmenter (Dinâmico e Baseado em ICP):** Cria micro-segmentos dinâmicos de leads usando os dados enriquecidos e modelos preditivos (Scikit-learn, XGBoost) que estimam a probabilidade de resposta, fit com o Ideal Customer Profile (ICP), e potencial de agendamento. Utiliza `Pinecone` para armazenar embeddings do ICP e comparar com embeddings de leads para scoring de fit.
*   **ContextForge (Hiper-Contextual e Relevante):** Gera "icebreakers", ganchos (`hooks`) e corpos de email/mensagem *altamente específicos, relevantes e referenciais* (`GPT-4o`, `Claude 3 Haiku`) com base no perfil 360° do lead, no ICP da campanha, e em sinais de intenção ou eventos recentes (e.g., novo round de investimento, lançamento de produto, participação em evento). Inclui capacidade de gerar múltiplas variações ("Arm Z") para A/B testing.
*   **Multi-Cadence Orchestrator (Dinâmico, Adaptativo e Otimizado):** Gerencia fluxos de contato multicanal (Email via Agente 001/Sendgrid, LinkedIn DMs/conexões via scripting seguro, WhatsApp via Agente 002/Meta Cloud API), ajustando a sequência, o conteúdo e o timing dos touchpoints em tempo real com base nas interações do lead (aberturas, cliques, visualizações de perfil, respostas) e em modelos de RL que otimizam a cadência para conversão. Inclui `Opt-in Whisper` para canais que exigem consentimento explícito.
*   **Auto-Booker (Integrado e Inteligente):** Facilita o agendamento de reuniões (integrado com Calendly, Google Calendar, Microsoft Outlook Calendar), agora mais integrado com o status na cadência (e.g., sugere horários apenas após um lead atingir um certo score de engajamento) e com feedback do CRM para evitar conflitos ou agendamentos com leads já em processo.
*   **CRM Results Feedback Loop (Contínuo e Granular):** Puxa dados do CRM (`Salesforce`, `HubSpot` via `CRMBridge`) sobre a qualidade dos leads gerados, taxa de conversão para MQL/SQL, oportunidades criadas, valor das oportunidades, e motivos de perda/ganho. Esses dados alimentam os modelos de predição do `Predictive Micro-Segmenter`, as estratégias de copy do `ContextForge`, e os modelos de otimização do `Multi-Cadence Orchestrator`.
*   **Experimentation Module (Arm Z e A/B Testing Robusto):** Permite testar sistematicamente variações radicais ("Arm Z") e incrementais (A/B/n) de ICPs, segmentos, fontes de dados, mensagens, canais e cadências em subconjuntos controlados de leads, com análise estatística dos resultados para identificar as estratégias mais eficazes.

### 5. Mecanismos/Tecnologias Refatorados
*   **Enriquecimento de Dados:** `Playwright` para scraping dinâmico, APIs de `Clearbit`, `Hunter.io`, `BuiltWith`. `RSSBridge` para monitoramento de notícias/blogs.
*   **Modelagem Preditiva:** Python com `scikit-learn`, `XGBoost`, `spaCy` (para NLP em ganchos). `MLflow` para gerenciamento do ciclo de vida dos modelos.
*   **Geração de Conteúdo:** `GPT-4o`, `Claude 3 Haiku` (via `LLM Orchestration Service`).
*   **Orquestração de Cadência:** `LangGraph` ou `Temporal.io` para definir e executar as sequências de outreach complexas e adaptativas.
*   **Armazenamento:** `PostgreSQL` para dados de leads, empresas, interações, e resultados de campanhas. `Pinecone` para embeddings de ICPs e leads. `Redis` para caching de perfis e gerenciamento de estado em tempo real das cadências.
*   **Comunicação Externa:** Integração com Agente 001 (Email), Agente 002 (WhatsApp). APIs diretas ou scripting seguro para LinkedIn.

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_006_refactored
name: OutreachAutomaton_v2
version: 0.2
description: "Generates qualified B2B leads and meetings via intelligent, predictive, and hyper-personalized multi-channel outreach."
triggers:
  - type: webhook # Manual trigger to start a new campaign or add leads
    path: "/outreach_automaton/start_campaign"
    config:
      workspace_id_param: "workspace_id"
      campaign_id_param: "campaign_id"
  - type: schedule # For processing ongoing cadences, lead scoring updates, etc.
    cron: "*/5 * * * *" # Every 5 minutes
    config:
      task: "process_cadence_and_lead_updates"
inputs_schema:
  - key: campaign_id
    type: string
    required: true # For webhook trigger
    description: "ID of the outreach campaign defining ICP, messaging templates, goals."
  - key: lead_list_url # Can be a GSheet, CSV URL, or direct payload
    type: string 
    required: false # If leads are provided directly or via another input
    description: "URL to a list of leads to process for the campaign."
  - key: lead_data_payload # Alternative to URL, for direct lead injection
    type: json
    required: false
    description: "Array of lead objects to process."
outputs_config:
  - key: campaign_performance_report
    type: json # Structured report
    description: "Detailed report on campaign performance: leads processed, contacted, engaged, meetings booked, pipeline value."
  - key: new_meeting_booked_event
    type: json
    description: "Event payload generated when a new meeting is successfully booked."
stack_details:
  language: python
  runtime: "FastAPI, LangGraph/Temporal, Scikit-learn"
  models_used:
    - "openai:gpt-4o (for ContextForge)"
    - "anthropic:claude-3-haiku (for variations)"
    - "custom_ml_models (XGBoost/RF for lead scoring via MLflow)"
  database_dependencies: ["PostgreSQL (leads, interactions)", "Pinecone (ICP/lead embeddings)", "Redis (cache, state)"]
  queue_dependencies: ["Redis + RQ (for task distribution)"]
  other_integrations: ["Clearbit API", "Hunter.io API", "LinkedIn Sales Navigator (via scripting)", "CRMBridge (Salesforce, HubSpot)", "Calendly API", "Agent001/002"]
memory_config:
  type: pinecone
  namespace_template: "outreach_icp_embeddings_ws_{{workspace_id}}"
  description: "Stores embeddings of Ideal Customer Profiles and lead profiles for scoring and segmentation."
```

### 7. Estrutura de Dados Refatorada
*   **PostgreSQL:**
    *   `outreach_campaigns`: `id`, `workspace_id`, `name`, `icp_definition_jsonb`, `messaging_templates_jsonb`, `goals_jsonb`, `status`.
    *   `outreach_leads`: `id`, `campaign_id`, `email`, `linkedin_url`, `company_name`, `enriched_data_jsonb`, `engagement_score`, `status_in_cadence`.
    *   `outreach_touchpoints`: `id`, `lead_id`, `channel`, `timestamp`, `type (auto_sent, manual_reply, opened, clicked)`, `content_snapshot_text`.
    *   `outreach_meetings`: `id`, `lead_id`, `meeting_time`, `calendar_event_id`, `status (scheduled, completed, cancelled)`.
*   **Pinecone:** Index `outreach_icp_embeddings_ws_{workspace_id}` com vetores para ICPs e perfis de leads.

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI.
*   **Orchestration:** LangGraph ou Temporal.io.
*   **ML/Data Science:** Scikit-learn, XGBoost, spaCy, MLflow, Pandas.
*   **LLM:** GPT-4o, Claude 3 Haiku (via `LLM Orchestration Service`).
*   **Scraping/Enrichment:** Playwright, Clearbit API, Hunter.io API.
*   **Vector DB:** Pinecone.
*   **Databases:** PostgreSQL, Redis.
*   **Queue:** Redis + RQ.
*   **Observability:** OpenTelemetry, Jaeger, Prometheus, Grafana (dashboard "Outreach Funnel Performance").

### 9. Triggers Refatorados
*   **Webhook:** `/outreach_automaton/start_campaign` para iniciar novas campanhas ou adicionar leads.
*   **Scheduled (Core Loop):** Processamento contínuo (e.g., every 5 mins) de leads em cadências ativas, verificação de interações, atualização de scores, e disparo do próximo touchpoint.
*   **Event-Driven (Internal):** Respostas de leads (via Email/LinkedIn/WhatsApp integrations) ou atualizações do CRM podem triggerar mudanças no estado da cadência ou re-priorização de leads.
*   **Breaker Logic:** Pausa automática de cadências para um lead se sinais negativos (e.g., "unsubscribe", resposta irritada detectada por LLM) são recebidos. Alertas para altas taxas de bounce ou baixas taxas de engajamento em uma campanha.

### 10. KPIs Refatorados
*   **Core:** Meetings Booked per SDR/Campaign, Lead-to-Meeting Conversion Rate, Pipeline Value Generated from Outreach.
*   **Efficiency:** Leads Processed per Hour, Enrichment Success Rate.
*   **Effectiveness:** Positive Reply Rate, Open Rate, Click-Through Rate (per channel/message variant).
*   **Quality:** MQL/SQL Conversion Rate from outreach leads (via CRM feedback).

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Vender uma nova solução de "AI-Powered Inventory Optimization" para D2C E-commerce com faturamento > $5M/ano.
1.  **Campanha Setup:** SDR define o ICP no IONFLUX (indústria, tamanho da empresa, tecnologias usadas como Shopify/Magento, personas de decisores como "Head of Ops", "E-commerce Manager"). Carrega uma lista de 500 empresas-alvo.
2.  **Enriquecimento e Segmentação:** `DataMiner Scraper` enriquece os dados das empresas e identifica contatos relevantes. `Predictive Micro-Segmenter` scoreia os leads; 150 são classificados como "Tier 1 - High Fit & Intent".
3.  **Geração de Conteúdo Contextual:** `ContextForge` analisa os "Tier 1 leads". Para "EmpresaX", detecta que acabaram de levantar um Series B (notícia). Para "EmpresaY", o Head of Ops postou no LinkedIn sobre problemas de stockout na Black Friday. Gera icebreakers e P.S. personalizados para cada um.
4.  **Orquestração Multicanal:** `Multi-Cadence Orchestrator` inicia a cadência:
    *   **Dia 1:** Email personalizado (via Agente 001) com o icebreaker relevante.
    *   **Dia 3 (se sem resposta, mas email aberto):** Pedido de conexão no LinkedIn com nota curta referenciando o email.
    *   **Dia 5 (se conectado, sem resposta):** LinkedIn DM com um case study conciso.
    *   **Dia 7 (se engajou no LinkedIn DM):** Sugestão de call com link Calendly do `Auto-Booker`.
5.  **Adaptação e Agendamento:** Lead da "EmpresaY" responde ao LinkedIn DM. Orquestrador pausa a cadência automática. SDR é notificado. Após breve troca de mensagens, SDR usa o `Auto-Booker` para confirmar a reunião.
6.  **Feedback Loop:** Reunião acontece. SDR marca no CRM como "SQL - Oportunidade Criada". `CRM Results Feedback Loop` ingere essa informação. O sistema aprende que o tipo de gancho usado para "EmpresaY" (dor específica de stockout) teve alta conversão para SQL.

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Automated Objection Handling):** LLM treinado para identificar objeções comuns em respostas e sugerir (ou autonomamente enviar, com supervisão) respostas pré-aprovadas ou agendar um follow-up específico para aquela objeção.
*   **V2.0 (Intent-Driven Dynamic ICP Refinement):** O agente monitora sinais de intenção em larga escala (e.g., empresas contratando para certas posições, mencionando certas tecnologias) e proativamente sugere novos micro-segmentos ou refina o ICP da campanha em tempo real.

### 13. Escape do Óbvio (Refatorado)
**"Anti-Outreach" Outreach:** Para leads C-level ultra-saturados, em vez de um pitch direto, o agente envia um "pedido de insight" hiper-personalizado e genuinamente relevante para o trabalho/posts recentes do executivo (e.g., "Adorei seu post sobre X. Estamos pesquisando Y, que se relaciona. Teria 2 min para uma pergunta rápida sobre sua experiência com Z? Prometo não vender nada."). O objetivo é iniciar uma conversa autêntica, com o booking da reunião sendo um resultado secundário e mais orgânico após o estabelecimento de um mínimo de rapport. Taxa de resposta significativamente maior para perfis "intocáveis".

Preencha. Refine. Lance.
---
## AGENTE 007 — SLACK BRIEF BUTLER / Concierge of Lightning Alignment (Refatorado)

### 1. Essência e Propósito do Agente 007 (Refatorado)
**Epíteto:** O Orquestrador da Clareza Coletiva em Canais de Comunicação
**TAGLINE:** TRANSFORMA CAOS DE MENSAGENS EM DECISÕES ACIONÁVEIS — INSTANTANEAMENTE
**Propósito Central Refatorado:** Aumentar a velocidade e a clareza da tomada de decisão e do alinhamento de equipes em plataformas de comunicação rápida (Slack, MS Teams, Discord, e potencialmente o ChatDock do IONFLUX), convertendo discussões textuais e em threads em resumos estruturados, decisões explícitas, itens de ação rastreáveis e conhecimento documentado. Minimiza a "fadiga de informação" e garante que o contexto crítico não se perca.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Sobrecarga de Informação:** Canais de chat são inundados com mensagens, tornando difícil acompanhar o que é crucial.
    *   **Decisões e Ações Perdidas:** Decisões importantes e itens de ação são frequentemente enterrados em longas threads ou se perdem entre conversas paralelas.
    *   **Contexto Fragmentado:** O conhecimento e o contexto de um projeto ficam espalhados por múltiplos canais e threads, dificultando a integração de novos membros ou a referência futura.
    *   **Reuniões para Sincronizar:** Muitas reuniões são agendadas apenas para extrair e alinhar informações que já foram discutidas de forma assíncrona, mas não foram devidamente capturadas.
    *   **Ambiguidade e Falta de Accountability:** A falta de clareza sobre quem é o responsável por qual ação e quais foram as decisões finais leva a atrasos e retrabalho.
*   **Oportunidade de Mercado Expandida:** Uma solução de IA que atua como um "secretário de projeto inteligente" dentro das plataformas de chat, não apenas resumindo, mas também estruturando a informação de forma proativa, facilitando a governança da decisão, rastreando ações e integrando o conhecimento gerado no chat com outras ferramentas de gestão de projeto e conhecimento (Notion, Jira, Canvas IONFLUX).

### 3. Capacidades Chave (Refatorado)
*   **Conversational Thread Siphon & Distiller (Aprimorado):**
    *   Monitora canais/threads designados ou é invocado sob demanda.
    *   Utiliza LLMs (`GPT-4o`, `Claude 3 Haiku`) com RAG (`Pinecone` sobre histórico do canal/projeto) para:
        *   Identificar e extrair pontos chave: decisões, problemas, itens de ação propostos, perguntas em aberto, sentimentos predominantes.
        *   Gerar resumos concisos e estruturados (e.g., formato "Situação-Problema-Solução-Ação" ou "Decisões-Ações-Bloqueios").
        *   Detectar automaticamente a necessidade de um resumo (e.g., thread longa e ativa sem conclusão clara).
*   **Action Item & Decision Tracker (Aprimorado):**
    *   Identifica explicitamente itens de ação e seus proprietários (sugeridos ou mencionados).
    *   Formata-os como tarefas claras.
    *   Permite confirmação de propriedade e prazos via botões interativos no chat.
    *   Registra decisões e ações em bases de conhecimento externas (`Notion`, `Jira`, `IONFLUX Canvas` ou `Playbook`) e/ou no `Data Store` interno do agente.
    *   Envia lembretes contextuais sobre ações pendentes.
*   **Structured Brief & Report Generator (Aprimorado):**
    *   Gera "Briefs Diários" ou "Resumos de Tópicos" em markdown, formatados para clareza.
    *   Permite templates de resumo customizáveis (definidos em YAML na configuração do agente).
    *   Inclui funcionalidade de "Briefcast Audio": transforma o resumo textual em um áudio curto e engajador (via TTS como `Azure Speech` ou `ElevenLabs`) para consumo rápido.
*   **Knowledge Integration & Contextualization (Novo):**
    *   Integra-se com o `IONFLUX Canvas` para postar resumos ou criar novos blocos de texto/tarefas.
    *   Conecta-se a bases de conhecimento (`Notion`, Confluence) para arquivar resumos e decisões, tornando o conhecimento do chat pesquisável e persistente.
    *   Utiliza o histórico e o contexto do projeto (armazenados em `Pinecone`) para tornar os resumos mais relevantes e informados.
*   **Interactive Governance & Feedback (Aprimorado "One-Click Approve"):**
    *   Posta resumos com botões interativos no chat (e.g., "Confirmar Decisão", "Aceitar Ação", "Solicitar Esclarecimento", "Marcar como Resolvido").
    *   As interações atualizam o status dos itens no `Data Store` do agente e nas ferramentas integradas.
    *   Coleta feedback sobre a qualidade e utilidade dos resumos para auto-aprimoramento (usando RL para otimizar o estilo e o foco dos resumos).
*   **Stakeholder Ping (Contextual e Inteligente):** Alerta stakeholders específicos apenas quando sua atenção é genuinamente necessária para uma decisão ou ação, evitando notificações desnecessárias.

### 4. Mecanismos/Tecnologias Refatorados
*   **Processamento de Linguagem:** `GPT-4o` / `Claude 3 Haiku` para sumarização, extração de entidades, análise de sentimento. `spaCy` para pré-processamento e identificação de estruturas linguísticas.
*   **Memória Contextual (RAG):** `Pinecone` para armazenar embeddings de mensagens anteriores, documentos de projeto, FAQs, para que o LLM gere resumos mais contextuais e precisos.
*   **Interação com Plataformas de Chat:** SDKs específicos (`Slack Bolt SDK`, `Microsoft Bot Framework`, `Discord.py`). Para o ChatDock do IONFLUX, usaria a API interna do `Chat Service`.
*   **Geração de Áudio:** `Azure Cognitive Services Speech` ou `ElevenLabs API` para TTS.
*   **Integração com Ferramentas Externas:** APIs de `Notion`, `Jira`, `Google Tasks`. `Zapier` ou `n8n` podem ser usados como camada de orquestração para algumas integrações se APIs diretas forem complexas.
*   **Armazenamento de Dados do Agente:** `PostgreSQL` para logs de resumo, decisões rastreadas, itens de ação, feedback de usuários.
*   **Orquestração de Tarefas:** `Redis + RQ` ou `Celery` para tarefas assíncronas (geração de áudios longos, sincronização com bases de conhecimento).

### 5. YAML de Definição (Refatorado)
```yaml
id: agent_007_refactored
name: CommunicationClarityButler # Nome mais genérico que SlackBriefButler
version: 0.2
description: "Intelligently distills chat conversations into actionable summaries, decisions, and tasks, integrating with knowledge bases."
triggers:
  - type: schedule
    cron: "0 9 * * 1-5" # Example: Weekday morning digest for specified channels
    config:
      target_channel_ids: ["channel_id_1", "channel_id_2"]
      summary_type: "daily_digest"
  - type: webhook # For on-demand summaries or specific event triggers from chat platforms
    path: "/communication_butler/summarize_thread"
    config:
      platform_param: "chat_platform" # e.g., slack, msteams, ionflux_chatdock
      channel_id_param: "channel_id"
      thread_id_param: "thread_id" # or message_timestamp_param
  - type: event # Triggered by other IONFLUX agents or services
    source: "ionflux_event_bus"
    config:
      event_type: "project_milestone_reached" # Example
      action: "generate_milestone_summary"
inputs_schema:
  - key: chat_platform_details # Contains platform, channel, thread/message identifiers
    type: json
    required: true
    description: "Details of the conversation source to be processed."
  - key: summary_request_details # Contains type of summary, desired output, audience
    type: json
    required: true
    description: "Parameters defining the summarization task."
  - key: custom_summary_template_id
    type: string
    required: false
    description: "ID of a user-defined summary template to use."
outputs_config:
  - key: structured_summary_markdown
    type: md
    description: "The generated summary in Markdown format."
  - key: audio_summary_url
    type: url
    description: "URL to the generated audio (TTS) version of the summary."
  - key: extracted_action_items_json
    type: json
    description: "JSON array of identified action items with owners and deadlines."
  - key: knowledge_base_update_status
    type: json
    description: "Status of attempts to update external knowledge bases (Notion, Jira)."
stack_details:
  language: python
  runtime: "FastAPI, LangChain"
  models_used:
    - "openai:gpt-4o (for summarization, action extraction)"
    - "anthropic:claude-3-haiku (for variations, sentiment analysis)"
    - "azure:speech_service / elevenlabs:tts (for Briefcast Audio)"
  database_dependencies: ["PostgreSQL (for agent's own data)", "Pinecone (for RAG context)"]
  queue_dependencies: ["Redis + RQ (for async tasks like TTS, KB sync)"]
  other_integrations: ["Slack API", "MS Graph API (Teams)", "Discord API", "Notion API", "Jira API", "IONFLUX ChatService API", "IONFLUX CanvasService API"]
memory_config:
  type: pinecone
  namespace_template: "comm_butler_context_ws_{{workspace_id}}_ch_{{channel_id}}"
  description: "Stores embeddings of conversation history and project documents for RAG."
```

### 6. Estrutura de Dados Refatorada
*   **PostgreSQL:**
    *   `butler_summaries`: `id`, `workspace_id`, `source_platform`, `source_channel_id`, `source_thread_id`, `summary_markdown_content`, `audio_summary_url`, `generation_timestamp`, `feedback_score`.
    *   `butler_action_items`: `id`, `summary_id (fk)`, `description`, `assigned_to_user_id`, `due_date`, `status (open, in_progress, completed, cancelled)`, `external_task_id (e.g., Jira issue ID)`.
    *   `butler_decisions`: `id`, `summary_id (fk)`, `description`, `decided_by_user_ids_array`, `decision_timestamp`, `external_ref_id`.
*   **Pinecone:** Índices por workspace/canal para embeddings de mensagens e documentos relevantes.

### 7. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI.
*   **LLM:** GPT-4o, Claude 3 Haiku (via `LLM Orchestration Service`).
*   **Vector DB:** Pinecone.
*   **TTS:** Azure Speech Service ou ElevenLabs API.
*   **Integrações:** Slack Bolt SDK, Microsoft Graph API, Discord.py, Notion API, Jira API.
*   **Database:** PostgreSQL.
*   **Queue:** Redis + RQ.
*   **Observability:** OpenTelemetry, Prometheus, Grafana (dashboard "Butler Performance & Clarity Scores").

### 8. Triggers Refatorados
*   **Scheduled:** Para resumos diários/semanais de canais ou projetos.
*   **Webhook/API Call:** Para resumos sob demanda (e.g., usuário clica "Summarize Thread" em um botão no chat, ou outro agente solicita um resumo).
*   **Event-Driven:** Triggerado por eventos como "fim de reunião" (se integrado a calendário), "documento importante adicionado ao projeto", ou quando uma thread atinge um certo comprimento ou nível de atividade sem uma conclusão clara.
*   **Breaker Logic:** Se a qualidade dos resumos (medida por feedback do usuário ou por métricas automáticas como taxa de "Solicitar Esclarecimento") cair abaixo de um limiar, o agente pode solicitar mais contexto, sugerir um template de discussão diferente para o canal, ou escalar para um "Community Manager" humano.

### 9. KPIs Refatorados
*   **Core:** Reduction in time spent in meetings (survey-based), Perceived clarity of project/task status (survey-based), Time saved by users (estimated from summary usage).
*   **Process:** Number of summaries generated, Action items identified and tracked to completion, Decisions logged.
*   **Qualidade:** User feedback ratings on summary utility, Read-to-Action ratio (how many summaries lead to confirmed actions).
*   **Sistema:** API latency for summary requests, Accuracy of action item extraction.

### 10. Exemplo Integrado (Refatorado)
**Cenário:** Uma equipe de produto discute o escopo do Sprint 3.2 no canal `#sprint-planning` do Slack. A thread tem mais de 50 mensagens.
1.  **Trigger:** Um membro da equipe clica num botão "✨ Butler: Summarize & Act" adicionado pelo agente a threads longas, ou o agente é acionado por um webhook `/communication_butler/summarize_thread`.
2.  **Processamento:**
    *   `Thread Siphon & Distiller` ingere as mensagens da thread. Usando RAG com o `Pinecone` (que contém o PRD do Sprint 3.2 e discussões anteriores), ele entende o contexto.
    *   O LLM (`GPT-4o`) gera um resumo focado em: 1. Features confirmadas para o sprint, 2. Features adiadas, 3. Blockers identificados, 4. Itens de ação com proprietários sugeridos.
3.  **Interação e Integração:**
    *   O resumo é postado no Slack com botões interativos: "Confirmar Feature X para @userA?", "Aceitar Blocker Y (Responsável @userB)?".
    *   `Action Item & Decision Tracker`: Conforme os usuários clicam, as ações e decisões são logadas no `PostgreSQL` do agente. Se a integração com Jira estiver ativa, um épico "Sprint 3.2" tem as features confirmadas adicionadas como User Stories, e blockers como Tasks.
    *   `Briefcast Audio`: Um link para a versão em áudio do resumo é incluído.
    *   `Knowledge Integration`: O resumo final e as decisões são enviados para uma página específica no Notion da equipe ("Sprint Planning Summaries").
4.  **Feedback:** Após algumas horas, o agente pode postar um follow-up discreto pedindo um rating (👍/👎) sobre a utilidade do resumo.

### 11. Expansão Dinâmica (Refatorada)
*   **V1.1 (Meeting Butler):** O agente pode ser convidado para reuniões virtuais (transcrevendo o áudio em tempo real via `Whisper`) e gerar o resumo, ações e decisões da reunião.
*   **V2.0 (Proactive Contextual Briefs):** Antes de uma reunião agendada, o Butler pode proativamente gerar um "pré-brief" para os participantes, resumindo discussões relevantes de chat e documentos relacionados ao tópico da reunião, garantindo que todos cheguem alinhados.

### 12. Escape do Óbvio (Refatorado)
**"Cross-Channel Signal Synthesis":** O Butler monitora múltiplos canais relacionados a um mesmo projeto ou tema (e.g., `#design`, `#dev`, `#marketing` para um lançamento). Ele não apenas resume individualmente, mas detecta sinais fracos, desalinhamentos ou dependências entre as discussões nesses canais. Gera um "Meta-Brief de Sincronia" que destaca esses pontos de atrito ou sinergia inter-canais, alertando para a necessidade de uma conversa focada entre representantes dos diferentes times antes que os problemas se agravem. Isso previne o clássico "silo de comunicação" de forma proativa.

Preencha. Refine. Lance.
---
## AGENTE 008 — CREATOR PERSONA GUARDIAN / Custodian of Authentic Voice (Refatorado)

### 1. Essência e Propósito do Agente 008 (Refatorado)
**Epíteto:** O Guardião Algorítmico da Alma Criativa e da Ressonância com a Audiência
**TAGLINE:** SUA VOZ É ÚNICA; NOSSA IA GARANTE QUE ELA SEJA OUVIDA E SENTIDA — SEMPRE
**Propósito Central Refatorado:** Capacitar criadores e marcas a manter e evoluir sua voz autêntica e persona de marca em escala, garantindo consistência em todo o conteúdo gerado (por humanos ou IA), otimizando a ressonância com a audiência-alvo e protegendo contra a diluição ou desalinhamento da identidade.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Inconsistência de Voz:** Com múltiplos contribuidores de conteúdo (equipes, freelancers, múltiplos agentes de IA), a voz e o tom da marca/criador podem se tornar fragmentados e inconsistentes.
    *   **Diluição da Persona:** A pressão para produzir volume de conteúdo pode levar à criação de material genérico que não reflete a identidade única da marca/criador.
    *   **Desalinhamento com a Audiência:** A persona da marca pode não estar otimizada para ressoar com o público-alvo desejado, ou pode não evoluir com as mudanças de preferência da audiência.
    *   **Dificuldade em Escalar Autenticidade:** Manter uma voz autêntica torna-se exponencialmente mais difícil à medida que a produção de conteúdo e o número de canais aumentam.
    *   **Feedback Subjetivo:** Avaliações de "tom" e "voz" são frequentemente subjetivas e difíceis de padronizar e aplicar consistentemente.
*   **Oportunidade de Mercado Expandida:** Uma solução de IA que não apenas "valida" o conteúdo contra uma persona definida, mas que também:
    *   Ajuda a *definir e refinar* a persona da marca/criador com base em dados.
    *   Fornece feedback *preditivo* sobre como diferentes estilos de conteúdo podem ressoar com segmentos específicos da audiência.
    *   Oferece sugestões de *reparação e aprimoramento* de estilo em tempo real.
    *   Monitora a *evolução* da persona e da audiência, sugerindo ajustes proativos.
    *   Permite a *transferência de estilo* para diferentes agentes de IA, garantindo que todos "falem a mesma língua".

### 3. Princípios Growth Looper & EmailWizard Aplicados
*   **Hyper-Segment (do EmailWizard):** O `Persona Guardian` pode micro-segmentar a audiência do criador/marca (com base em dados de engajamento, demografia, etc.) e analisar como a persona da marca ressoa com cada segmento, permitindo ajustes de tom para diferentes públicos sem perder a essência central.
*   **Dopamine Drip (do EmailWizard):** O agente pode sugerir uma cadência de evolução da persona, introduzindo pequenas variações de estilo ou temas ao longo do tempo e medindo a resposta da audiência para otimizar o "drip" de evolução da marca de forma a manter o engajamento.
*   **Feedback Loop (do Growth Looper):** A performance do conteúdo (engajamento, conversão, sentimento da audiência) em relação à sua aderência à persona (avaliada pelo agente) cria um feedback loop contínuo. Isso permite que o agente aprenda quais nuances da persona são mais eficazes e como a persona deve evoluir.

### 4. Capacidades Chave Expandidas
*   **Multimodal Persona Definition & Extraction (Aprimorado `Signature Extractor`):**
    *   Ingere uma ampla gama de conteúdos existentes da marca/criador: texto (posts, artigos, roteiros), áudio (podcasts, narrações), vídeo (estilo visual, ritmo de edição, linguagem corporal), imagens (estética, paleta de cores).
    *   Utiliza LLMs multimodais (`GPT-4o Vision`, `CLIP`) e modelos específicos (`Whisper` para áudio, Sentence Transformers para texto) para extrair um "fingerprint" de persona 360°, que inclui:
        *   **Léxico e Estilo de Escrita:** Vocabulário chave, estrutura frasal, uso de gírias/jargões, tom formal/informal, humor, etc.
        *   **Estilo Visual:** Paleta de cores predominante, estilo de edição, tipografia, composição de imagens/vídeos.
        *   **Estilo Auditivo:** Tom de voz, ritmo da fala, música de fundo preferida.
        *   **Valores e Temas Recorrentes:** Tópicos e valores implícitos/explícitos no conteúdo.
    *   Armazena esse fingerprint como um conjunto de embeddings e metadados em `Pinecone` e `PostgreSQL`.
*   **Content Authenticity & Resonance Scoring (Aprimorado `Tone Validator`):**
    *   Avalia novo conteúdo (texto, imagem, roteiro de vídeo, áudio) em relação ao fingerprint da persona definida.
    *   Fornece um score de "Autenticidade da Persona" (0-1).
    *   **NOVO:** Fornece um score preditivo de "Ressonância com Audiência-Alvo" (0-1), utilizando o fingerprint da persona, o conteúdo em si, e um modelo treinado com dados de engajamento da audiência-alvo (se disponível).
*   **AI-Powered Style Repair & Enhancement (Aprimorado `Style Repair`):**
    *   Se o score de autenticidade ou ressonância estiver baixo, o agente usa LLMs (`GPT-4o`, `Claude 3 Haiku`) para:
        *   Sugerir edições específicas para alinhar o conteúdo com a persona, preservando a mensagem central.
        *   Oferecer variações do conteúdo em diferentes "sabores" da persona (e.g., "mais espirituoso", "mais direto").
        *   **NOVO:** Adaptar o conteúdo para diferentes canais ou segmentos de audiência, mantendo o núcleo da persona.
*   **Persona Evolution & Drift Monitor (Aprimorado `Evolution Monitor`):**
    *   Monitora continuamente o conteúdo produzido e o feedback da audiência.
    *   Detecta desvios graduais (drift) da persona central.
    *   Diferencia entre "desvio negativo" (perda de autenticidade) e "evolução positiva" (adaptação bem-sucedida da persona que leva a maior engajamento).
    *   Alerta o usuário sobre desvios negativos e pode sugerir "cursos de correção" ou workshops de realinhamento de persona.
*   **Persona Style Transfer Hub (Novo):**
    *   Atua como um "hub de estilo" para outros agentes IONFLUX.
    *   Quando outro agente (e.g., `Email Wizard`, `Outreach Automaton`) precisa gerar conteúdo para uma marca/criador, ele pode consultar o `Persona Guardian` para obter diretrizes de estilo, prompts específicos, ou até mesmo para que o `Persona Guardian` refine o conteúdo gerado pelo outro agente para garantir a aderência à persona.

### 5. Mecanismos/Tecnologias Refatorados
*   **LLMs Multimodais:** `GPT-4o Vision` para análise de imagens/vídeos e geração de texto alinhado. `Claude 3 Haiku` para reparos e variações de estilo.
*   **Embeddings:** `OpenAI CLIP` para embeddings visuais, `Sentence-Transformers` para embeddings textuais, `OpenAI Whisper` para transcrição e potencial embedding de áudio.
*   **Vector DB:** `Pinecone` para armazenar e consultar os fingerprints multimodais da persona.
*   **Machine Learning:** Modelos de classificação/regressão (e.g., `scikit-learn`) para treinar o score de "Ressonância com Audiência-Alvo" com base em dados históricos de conteúdo e engajamento.
*   **Orquestração:** `LangGraph` para definir os fluxos de análise, reparo e feedback.

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_008_refactored
name: CreatorPersonaGuardian_v2
version: 0.2
description: "Defines, protects, and evolves authentic brand/creator personas, ensuring content resonance and consistency across all channels."
triggers:
  - type: webhook
    path: "/persona_guardian/validate_content" # For validating a piece of content
    config:
      workspace_id_param: "workspace_id"
      creator_id_param: "creator_id" # or brand_id
      content_url_param: "content_asset_url" # or content_text_param
  - type: event
    source: "ionflux_content_creation_event" # e.g., from Canvas when new text block is finalized
    config:
      event_type: "new_content_block_created"
  - type: schedule
    cron: "0 0 * * 0" # Weekly
    config:
      task: "persona_evolution_analysis_and_report"
      workspace_id: "all_active" # Can be parameterized
inputs_schema:
  - key: creator_id_or_brand_id
    type: string
    required: true
    description: "Identifier for the creator or brand persona to use."
  - key: content_to_analyze_text
    type: string
    required: false
    description: "Text content to validate/repair."
  - key: content_to_analyze_url # For images, videos, audio files
    type: string
    required: false
    description: "URL of the multimodal content to validate/repair."
  - key: target_audience_segment_id
    type: string
    required: false
    description: "Optional: Specify a target audience segment for resonance prediction."
  - key: style_transfer_source_agent_id # For Persona Style Transfer Hub
    type: string
    required: false
    description: "ID of the agent whose output needs style alignment."
outputs_config:
  - key: authenticity_score
    type: float # Range 0.0 - 1.0
    description: "Confidence score of content alignment with the defined persona."
  - key: resonance_score_predicted
    type: float # Range 0.0 - 1.0
    description: "Predicted resonance score with the target audience."
  - key: repaired_content_suggestions_json
    type: json # Could be array of suggested text/visual changes
    description: "Suggestions for repairing or enhancing content style and tone."
  - key: persona_evolution_report_md
    type: md
    description: "Weekly report on persona consistency, drift, and audience resonance."
stack_details:
  language: python
  runtime: "FastAPI, LangChain, LangGraph"
  models_used:
    - "openai:gpt-4o-vision (for multimodal analysis & generation)"
    - "anthropic:claude-3-haiku (for style repair variations)"
    - "openai:clip-vit-large-patch14"
    - "openai:whisper-large-v3"
    - "sentence-transformers:all-mpnet-base-v2"
    - "custom_ml_models (for resonance prediction)"
  database_dependencies: ["PostgreSQL (persona metadata)", "Pinecone (persona embeddings)"]
  queue_dependencies: ["Redis + RQ (for async content processing)"]
  other_integrations: ["IONFLUX AgentService (for style hub functionality)", "Social Media APIs (for audience data, read-only)"]
memory_config:
  type: pinecone
  namespace_template: "persona_fingerprints_ws_{{workspace_id}}_id_{{creator_id_or_brand_id}}"
  description: "Stores multimodal embeddings and stylistic parameters defining the persona."
```

### 7. Estrutura de Dados Refatorada
*   **PostgreSQL:**
    *   `persona_definitions`: `id`, `workspace_id`, `name (creator/brand name)`, `persona_type (creator/brand)`, `core_lexicon_jsonb`, `style_rules_yaml`, `visual_palette_jsonb`, `audio_profile_jsonb`, `target_audience_profile_id (fk)`.
    *   `persona_content_validations`: `id`, `persona_id (fk)`, `timestamp`, `content_url_or_text_md5`, `authenticity_score`, `resonance_score`, `suggested_repairs_jsonb`.
    *   `audience_segments`: `id`, `workspace_id`, `name`, `defining_criteria_jsonb`.
    *   `audience_resonance_data`: `content_id`, `segment_id`, `engagement_metrics_jsonb`.
*   **Pinecone:** Índices para fingerprints de persona (texto, imagem, áudio embeddings) e para conteúdo analisado.

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI.
*   **LLMs/Embeddings:** GPT-4o Vision, Claude 3 Haiku, CLIP, Whisper, Sentence-Transformers (via `LLM Orchestration Service`).
*   **Vector DB:** Pinecone.
*   **Database:** PostgreSQL.
*   **Queue:** Redis + RQ.
*   **ML:** Scikit-learn/TensorFlow for resonance models, MLflow.
*   **Observability:** OpenTelemetry, Prometheus, Grafana (dashboard "Persona Health & Resonance").

### 9. Triggers Refatorados
*   **Webhook:** `/persona_guardian/validate_content` para validação sob demanda de um conteúdo específico.
*   **Event-Driven:** Triggered por outros agentes IONFLUX (e.g., `Email Wizard` antes de enviar um email, `TikTok Stylist` antes de postar um vídeo) para garantir alinhamento de persona. Triggered pela criação de novo conteúdo no `Canvas Service`.
*   **Scheduled:** Análise semanal (`persona_evolution_analysis_and_report`) da consistência geral do conteúdo produzido e da ressonância com a audiência. Recalcular/refinar fingerprints da persona com base em novo conteúdo "canônico".
*   **Breaker Logic:** Se a pontuação média de autenticidade do conteúdo de uma marca/criador cair consistentemente abaixo de um limiar (e.g., <0.75 por uma semana), ou se a ressonância com a audiência-alvo diminuir significativamente, o agente envia um alerta para o workspace e pode sugerir um "workshop de realinhamento de persona".

### 10. KPIs Refatorados
*   **Core:** Average Authenticity Score across all content, Predicted vs. Actual Audience Engagement Lift due to persona alignment.
*   **Process:** Percentage of content automatically repaired/enhanced, Time saved in content review cycles.
*   **Qualidade:** User satisfaction with persona definition tools and repair suggestions.
*   **Sistema:** Accuracy of resonance prediction models.

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Um criador de culinária conhecido por seu tom "engraçado e um pouco caótico" está usando um agente LLM (via IONFLUX) para ajudar a gerar scripts para seus vídeos do TikTok.
1.  **Definição da Persona:** O `Persona Guardian` já analisou os 50 vídeos anteriores mais populares do criador, seu blog e posts em redes sociais, criando um "fingerprint de persona" que captura seu léxico único (e.g., uso de gírias específicas), ritmo de fala, estilo visual de seus vídeos (cortes rápidos, close-ups de comida), e o tom humorístico.
2.  **Geração de Conteúdo por Outro Agente:** O criador usa um "Agente Gerador de Roteiros para TikTok" dentro do IONFLUX para um novo vídeo sobre "falhas épicas na cozinha". O agente gerador produz um roteiro.
3.  **Validação e Reparo via Persona Style Transfer Hub:**
    *   Antes que o roteiro seja finalizado, o "Agente Gerador de Roteiros" envia o rascunho para o `Persona Guardian` através do `webhook /persona_guardian/validate_content` (ou um evento interno).
    *   O `Persona Guardian` analisa o roteiro. `Authenticity_score`: 0.65 (baixo). `Resonance_score_predicted` (para a audiência principal do criador): 0.70. O Guardian detecta que o roteiro é muito formal e não tem o humor caótico característico.
    *   `AI-Powered Style Repair & Enhancement` sugere modificações: adiciona piadas contextuais, substitui algumas palavras por gírias do léxico do criador, e sugere momentos para inserção de efeitos sonoros de "falha" que são comuns em seus vídeos.
    *   O roteiro reparado agora tem `Authenticity_score`: 0.92 e `Resonance_score_predicted`: 0.88.
4.  **Feedback e Evolução:** O criador usa o roteiro reparado, e o vídeo tem alta performance. Esses dados de engajamento são usados pelo `Performance Feedback Loop` para reforçar os parâmetros do fingerprint da persona do criador, especialmente a eficácia do humor "caótico".
5.  **Monitoramento Contínuo:** O `Persona Evolution & Drift Monitor` acompanha os vídeos subsequentes. Se o criador começar a usar um tom consistentemente mais sério e o engajamento cair, o agente pode alertá-lo sobre esse "desvio negativo".

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Persona A/B Testing):** Permitir que o criador teste variações sutis de sua persona (e.g., "mais sarcástico" vs. "mais bobo") em diferentes peças de conteúdo e canais, com o `Persona Guardian` analisando qual variação ressoa melhor com qual segmento da audiência.
*   **V2.0 (Cross-Platform Persona Consistency Engine):** Para criadores/marcas com presença em múltiplas plataformas (TikTok, YouTube, Instagram, Blog), o agente analisa e ajuda a manter uma persona central consistente, ao mesmo tempo que permite adaptações de estilo nativas para cada plataforma.

### 13. Escape do Óbvio (Refatorado)
**"Authentic Resonance Mapping":** Em vez de apenas garantir que o conteúdo *pareça* com o do criador, o agente foca em identificar e amplificar os elementos da persona que *mais ressoam* com os segmentos de audiência de *maior valor* para o criador (e.g., aqueles que mais convertem em vendas de produtos, assinaturas, etc.). Ele pode descobrir que um aspecto subutilizado da persona do criador (e.g., um hobby específico que ele raramente menciona) tem um potencial de ressonância enorme com um nicho de audiência altamente lucrativo, e então sugerir formas de trazer esse aspecto mais para o centro do conteúdo.

Preencha. Refine. Lance.
---
## AGENTE 009 — BADGE MOTIVATOR / Gamemaster of Relentless Progress (Refatorado)

### 1. Essência e Propósito do Agente 009 (Refatorado)
**Epíteto:** O Arquiteto de Jornadas de Engajamento e Maestria Contínua
**TAGLINE:** TRANSFORMA AÇÃO EM HÁBITO, HÁBITO EM CONQUISTA, CONQUISTA EM IDENTIDADE
**Propósito Central Refatorado:** Impulsionar o engajamento do usuário, a adoção de features, a conclusão de tarefas e a colaboração produtiva dentro da plataforma IONFLUX (e potencialmente em sistemas integrados), através de um sistema de gamificação sofisticado, adaptativo e socialmente conectado, que recompensa progresso significativo e comportamentos desejados.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Desmotivação e Churn:** Usuários frequentemente perdem o interesse ou se sentem sobrecarregados, levando à baixa adoção de features e eventual churn.
    *   **Falta de Reconhecimento do Progresso:** Muitos marcos importantes no trabalho de um criador ou de uma equipe de marketing (e.g., consistência na publicação, aprendizado de novas ferramentas, colaborações bem-sucedidas) não são visualmente reconhecidos ou celebrados.
    *   **Dificuldade em Incentivar Comportamentos Desejados:** Plataformas lutam para guiar usuários a explorar features mais avançadas ou a seguir "melhores práticas" de forma orgânica.
    *   **Isolamento e Falta de Pertencimento:** Usuários podem se sentir isolados em suas jornadas, sem um senso de comunidade ou reconhecimento compartilhado.
*   **Oportunidade de Mercado Expandida:** Uma plataforma de gamificação que vai além de simples pontos e badges, oferecendo:
    *   **Jornadas de Progressão Personalizadas:** Caminhos de desenvolvimento adaptados aos objetivos e ao nível de experiência do usuário/workspace.
    *   **Recompensas Intrínsecas e Extrínsecas:** Foco tanto na satisfação da maestria e do reconhecimento (intrínseco) quanto em benefícios tangíveis (extrínseco).
    *   **Gamificação Social e Colaborativa:** Incentivar a competição saudável, a colaboração e o reconhecimento entre pares.
    *   **Gamificação Aplicada a Agentes IA:** Estender o sistema de recompensas e progressão para os próprios agentes IA, incentivando seu uso eficaz e a otimização de suas configurações.

### 3. Princípios Growth Looper & EmailWizard Aplicados
*   **Hyper-Segment (do EmailWizard):** O `Badge Motivator` pode criar "trilhas de badges" ou desafios específicos para diferentes tipos de usuários (e.g., "Criador Iniciante", "Especialista em Shopify", "Mestre de Automação de Email") ou para diferentes workspaces com base em seus objetivos.
*   **Dopamine Drip (do EmailWizard):** A liberação de badges, pontos de XP e recompensas é cuidadosamente programada para criar um "drip" de dopamina, mantendo os usuários engajados e motivados a continuar progredindo. Notificações sobre "quase lá" para o próximo badge ou streaks.
*   **Feedback Loop (do Growth Looper):** O sistema monitora quais badges e recompensas são mais eficazes em impulsionar comportamentos desejados e ajusta a dificuldade, os critérios ou a atratividade das recompensas ao longo do tempo. Usuários podem dar feedback sobre os desafios.

### 4. Capacidades Chave Expandidas
*   **Dynamic XP & Achievement Engine (Aprimorado `XP Engine`):**
    *   Atribui XP (Pontos de Experiência) e rastreia progresso para uma vasta gama de ações e eventos mensuráveis dentro do IONFLUX:
        *   Criação e uso de Canvas Pages, Blocos.
        *   Configuração e execução bem-sucedida de Agentes.
        *   Interações no ChatDock (e.g., iniciar threads úteis, responder rapidamente).
        *   Conexão de SaaS (Shopify, TikTok).
        *   Conclusão de "Desafios" ou "Missões" propostas pelo sistema.
        *   Colaboração (e.g., ser mencionado, contribuir para um projeto compartilhado).
    *   Permite que administradores de workspace definam "eventos customizados" para atribuição de XP.
*   **Generative & Symbolic Badge Forge (Aprimorado `Badge Forge`):**
    *   Gera insígnias (badges) SVG ou PNG únicas e esteticamente atraentes, não apenas baseadas em templates, mas potencialmente usando IA generativa de imagens (`DALL-E 3`, `Midjourney` via API) para criar visuais de badges que reflitam verdadeiramente a natureza da conquista.
    *   Os badges têm nomes criativos, descrições e "flavor text" (gerados por LLM como `GPT-4o`) que contam uma pequena história sobre a conquista.
    *   Suporta "meta-badges" (badges por colecionar outros badges) e "badges secretos" (por descobrir features escondidas ou realizar ações raras).
*   **Adaptive Leaderboards & Social Feeds (Aprimorado `Leaderboard Pulse`):**
    *   Cria leaderboards dinâmicos e filtráveis (e.g., por XP, por tipo de badge, por equipe dentro de um workspace, entre workspaces de perfil similar – com consentimento).
    *   Inclui "leaderboards de agentes IA", onde os agentes competem com base em KPIs de eficiência ou ROI gerado, incentivando os usuários a otimizar suas configurações.
    *   Um "Feed de Atividades/Conquistas" no workspace ou no perfil do usuário, onde novos badges e marcos importantes são anunciados, permitindo reações e comentários de outros membros.
*   **Intelligent Reward & Recognition Router (Aprimorado `Reward Router`):**
    *   Dispara webhooks ou notificações quando um usuário/agente atinge um novo nível, ganha um badge significativo ou completa uma "Quest".
    *   Recompensas podem ser:
        *   **Digitais/Simbólicas:** Novos avatares, temas de UI, acesso antecipado a features beta.
        *   **Funcionais:** Desbloqueio de limites mais altos (e.g., mais execuções de agentes, mais armazenamento), acesso a templates de agentes/canvas premium.
        *   **Externas (via Webhooks):** Cupons de desconto para serviços parceiros, doações para caridade em nome do usuário, etc.
    *   O sistema pode usar RL para aprender quais recompensas são mais motivadoras para diferentes segmentos de usuários.
*   **Quest & Challenge Designer (Novo):**
    *   Uma interface (ou configuração via YAML) para administradores de IONFLUX ou de workspaces criarem "Quests" ou "Desafios" – sequências de tarefas que, quando completadas, resultam em XP significativo e badges especiais.
    *   Exemplos: "Onboarding Quest: Configure seu primeiro Agente de Shopify e analise 1 semana de dados", "Power User Challenge: Automatize 5 processos usando 3 Agentes diferentes".

### 5. Mecanismos/Tecnologias Refatorados
*   **Motor de Eventos:** `Kafka` para ingerir eventos de atividade da plataforma em alta velocidade. `Apache Flink` ou `Spark Streaming` para processar esses eventos em tempo real e calcular XP/progresso.
*   **Geração de Badges:** `Pillow` e `SVGwrite` para badges baseados em template. APIs de IA generativa de imagem (`DALL-E 3`, `Midjourney API`) para badges únicos. `GPT-4o` para nomes e descrições.
*   **Armazenamento:** `PostgreSQL` para armazenar perfis de usuário/workspace (XP, level, badges conquistados, progresso em quests). `Redis` (Sorted Sets) para leaderboards em tempo real.
*   **CDN:** `Cloudflare R2` ou `AWS S3 + CloudFront` para servir os assets dos badges.
*   **Notificações:** Integração com `NotificationService` do IONFLUX para anunciar conquistas.

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_009_refactored
name: BadgeMotivator_v2
version: 0.2
description: "Drives user engagement, feature adoption, and productive habits through an adaptive and social gamification system."
triggers:
  - type: event_stream # Consumes from internal IONFLUX event bus
    source: "kafka_topic_ionflux_platform_events"
    config:
      topic: "ionflux.platform.activity_events" # Events like 'agent_run_success', 'canvas_page_created', 'saas_connected'
      consumer_group: "badge_motivator_v2_consumer"
  - type: schedule 
    cron: "0 0 * * *" # Daily
    config:
      task: "daily_streak_checks_and_leaderboard_updates"
inputs_schema: # Schema for events from Kafka
  - key: event_type 
    type: string
    required: true
    description: "Type of platform event that occurred (e.g., 'agent_run_success', 'quest_step_completed')."
  - key: user_id
    type: string
    required: true
    description: "User ID associated with the event."
  - key: workspace_id
    type: string
    required: true
    description: "Workspace ID."
  - key: event_properties 
    type: json # Specific details of the event, e.g., agent_id, feature_used, kpi_achieved
    required: false
    description: "Additional properties of the event relevant for XP calculation or badge criteria."
outputs_config:
  - key: xp_awarded_event
    type: json
    description: "Event detailing XP awarded, new level achieved, etc."
  - key: badge_unlocked_event
    type: json
    description: "Event detailing badge unlocked, including badge name, description, image URL."
  - key: reward_triggered_event
    type: json
    description: "Event detailing any tangible reward unlocked."
stack_details:
  language: python
  runtime: "FastAPI, Flink/Spark Streaming"
  models_used:
    - "openai:gpt-4o (for badge naming, descriptions)"
    - "openai:dall-e-3 (for generative badge visuals, if budget allows)"
  database_dependencies: ["PostgreSQL (user progression, badges)", "Redis (leaderboards, streaks)"]
  queue_dependencies: ["Kafka (for platform events)", "Redis + RQ (for reward fulfillment tasks)"]
  other_integrations: ["IONFLUX NotificationService", "IONFLUX UserService", "CDN (for badge assets)"]
memory_config:
  type: none # Primarily relies on structured DB and event stream processing.
  description: "Gamification state is stored in PostgreSQL and Redis."
```

### 7. Estrutura de Dados Refatorada
*   **PostgreSQL:**
    *   `user_xp_levels`: `user_id`, `workspace_id`, `current_xp`, `current_level`, `last_activity_timestamp`.
    *   `badges_definitions`: `badge_id`, `name`, `description`, `image_url_template`, `criteria_jsonb (rules to unlock)`.
    *   `user_unlocked_badges`: `user_id`, `badge_id`, `unlocked_timestamp`, `workspace_id_context`.
    *   `quests_definitions`: `quest_id`, `name`, `description`, `steps_jsonb (array of criteria/tasks)`, `reward_xp`, `reward_badge_id (fk)`.
    *   `user_quest_progress`: `user_id`, `quest_id`, `current_step`, `status (in_progress, completed)`.
*   **Redis:** Sorted sets for leaderboards (`leaderboard_global_xp`, `leaderboard_ws_{workspace_id}_xp`). Hashes for user streaks.

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI (for API), Apache Flink or Spark Streaming (for event processing).
*   **Event Streaming:** Kafka.
*   **Databases:** PostgreSQL, Redis.
*   **Image Generation (Badges):** Pillow/SVGwrite, potentially DALL-E 3 / Midjourney API.
*   **LLM (Text for Badges):** GPT-4o (via `LLM Orchestration Service`).
*   **Observability:** OpenTelemetry, Prometheus, Grafana (dashboard "User Engagement & Gamification KPIs").

### 9. Triggers Refatorados
*   **Primary:** Continuous consumption from Kafka topic `ionflux.platform.activity_events`.
*   **Scheduled:** Daily checks for streaks, leaderboard updates, potential new challenge assignments.
*   **Breaker Logic:** If suspicious activity is detected (e.g., massive XP gain in short time for a user, indicating possible gaming of the system), flag the user account for review and temporarily pause further XP/badge awards for them.

### 10. KPIs Refatorados
*   **Core:** Daily Active Users (DAU) / Monthly Active Users (MAU) ratio, Feature Adoption Rate (for key features targeted by quests/badges), User Retention Rate (cohort analysis).
*   **Engagement:** Average XP earned per user/week, Badges unlocked per user, Quest completion rate.
*   **Social:** Leaderboard engagement (views, shares if applicable), Reactions/comments on achievement announcements.
*   **Sistema:** Event processing latency.

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Um novo usuário ("Alex") se junta ao IONFLUX e começa a explorar.
1.  **Onboarding Quest:** Alex é automaticamente inscrito na "IONFLUX Kickstart Quest".
    *   **Step 1: "Connect your first SaaS!"** Alex conecta sua loja Shopify. `Event: saas_connected`. `XP Engine` awards +50 XP. `Badge Forge` (via `NotificationService`) posts: "🎉 @Alex just earned the 'Shopify Connector' badge! (+50 XP)".
    *   **Step 2: "Create your first Canvas Page!"** Alex cria uma página. `Event: canvas_page_created`. +20 XP.
    *   **Step 3: "Run your first Agent!"** Alex configura e roda o `Revenue Tracker Lite`. `Event: agent_run_success`. +100 XP. Alex atinge Nível 2.
2.  **Leaderboard & Social:** Alex aparece no leaderboard do seu workspace (se compartilhado). Seus colegas podem reagir ao anúncio do badge no feed de atividades.
3.  **Streak Bonus:** Alex usa o IONFLUX por 3 dias seguidos (detectado por `daily_streak_checks`). Recebe um badge "Consistent Explorer" e um bônus de +75 XP.
4.  **Agent Optimization Reward:** O `Revenue Tracker Lite` de Alex, após rodar por uma semana, atinge um KPI interno de "dados consistentemente atualizados". O próprio *agente* (ou a configuração do agente por Alex) recebe um badge "Reliable Reporter" e XP, que pode ser visível no `Agent Snippet` ou no `Agent Hub`.

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Team-Based Quests & Leaderboards):** Introduzir desafios e leaderboards para equipes dentro de um workspace, fomentando a colaboração para atingir objetivos gamificados.
*   **V2.0 (User-Generated Badges & Challenges):** Permitir que administradores de workspace (ou até usuários avançados) criem seus próprios badges e desafios customizados para suas equipes, alinhados com metas específicas do workspace.

### 13. Escape do Óbvio (Refatorado)
**"Serendipity Badges" & "Hidden Quests":** O sistema inclui uma série de badges e quests "secretas" que não são listadas publicamente. Elas são desbloqueadas ao realizar combinações raras de ações, explorar features menos óbvias, ou até mesmo ao se recuperar de uma "falha" de forma construtiva (e.g., um agente que falhou e foi corrigido pelo usuário, gerando um badge "Debug Dominator"). Isso incentiva a exploração profunda e recompensa a curiosidade, adicionando uma camada de "descoberta" à gamificação.

Preencha. Refine. Lance.
---
## AGENTE 010 — REVENUE TRACKER LITE / Ledger of the Hidden Margin (Refatorado)

### 1. Essência e Propósito do Agente 010 (Refatorado)
**Epíteto:** O Analista Financeiro Pessoal da Sua Loja, Focado em Lucratividade Real
**TAGLINE:** FATURAMENTO É VAIDADE, LUCRO É SANIDADE, FLUXO DE CAIXA É REI — NÓS MOSTRAMOS OS TRÊS.
**Propósito Central Refatorado:** Fornecer aos proprietários de lojas e-commerce (inicialmente Shopify) uma visão clara, concisa e *acionável* da sua lucratividade real em tempo (quase) real, rastreando não apenas a receita, mas também os custos variáveis diretos (COGS, taxas de transação, frete, custos de apps Shopify), e calculando a margem de contribuição. O foco é em insights que levem a decisões de otimização de preço, custo e marketing.

### 2. Análise Aprofundada do "Problema Raiz" e "Oportunidade de Mercado"
*   **Problema Raiz Detalhado:**
    *   **Visão Superficial da Receita:** Muitos lojistas focam excessivamente na receita bruta, sem uma compreensão clara dos custos diretos que impactam cada venda.
    *   **Complexidade no Cálculo de Custos:** COGS pode variar, taxas de gateway são percentuais, custos de frete são dinâmicos, e taxas de apps Shopify são muitas vezes esquecidas no cálculo da margem por pedido. Planilhas manuais são propensas a erros e demoradas.
    *   **Decisões de Marketing e Precificação Desinformadas:** Sem entender a margem real por produto ou pedido, é difícil otimizar preços, descontos, ou o ROI de campanhas de marketing.
    *   **Atraso na Identificação de Problemas de Lucratividade:** Problemas com fornecedores aumentando COGS, ou taxas de frete subestimadas podem erodir a lucratividade por semanas antes de serem percebidos em relatórios contábeis tradicionais.
*   **Oportunidade de Mercado Expandida:** Uma ferramenta "Lite" que se integra profundamente com a plataforma de e-commerce (Shopify) e, crucialmente, com os *outros agentes IONFLUX* para:
    *   Automatizar a coleta de dados de receita e custos variáveis.
    *   Fornecer um dashboard simples e compreensível da margem de contribuição e do ponto de equilíbrio.
    *   Gerar alertas e insights *acionáveis* (e.g., "Seu produto X está com margem negativa após custos de marketing da Campanha Y", "Aumento no custo de frete para a região Z está impactando sua lucratividade").
    *   Servir como fonte de dados financeiros para outros agentes (e.g., `Shopify Sales Sentinel` poderia usar dados de margem para priorizar alertas; `UGC Matchmaker` poderia usar dados de lucratividade de produto para focar campanhas UGC).

### 3. Princípios Growth Looper & EmailWizard Aplicados
*   **Hyper-Segment (do EmailWizard):** O `Revenue Tracker Lite` pode, no futuro, segmentar a análise de lucratividade por produto, SKU, coleção, canal de marketing, ou até mesmo por segmento de cliente, fornecendo insights muito granulares.
*   **Dopamine Drip (do EmailWizard):** Em vez de apenas mostrar números, o agente pode fornecer "gotas de dopamina" na forma de:
    *   Alertas positivos: "Parabéns! Sua margem no produto Y aumentou 5% esta semana."
    *   Insights acionáveis que levam a melhorias rápidas: "Dica: Aumentar o preço do Produto Z em R$2 pode dobrar sua margem líquida sem impacto significativo esperado nas vendas."
    *   Relatórios de progresso que mostram o impacto das otimizações feitas.
*   **Feedback Loop (do Growth Looper):**
    *   **Interno:** O agente aprende quais insights e alertas são mais "clicados" ou levam a ações pelo usuário (e.g., se o usuário ajusta um preço após um alerta), e otimiza para fornecer informações mais relevantes.
    *   **Externo (Sinergia com outros Agentes):**
        *   Se o `Outreach Automaton` (Agente 006) roda uma campanha de marketing, o `Revenue Tracker Lite` mede o impacto real na lucratividade dos produtos promovidos. Esse feedback de ROI refina as estratégias do `Outreach Automaton`.
        *   Se o `Shopify Sales Sentinel` (Agente 004) detecta uma queda nas vendas de um produto lucrativo, ele pode alertar o `Revenue Tracker Lite` para investigar se há um problema de margem, ou vice-versa.

### 4. Capacidades Chave Expandidas
*   **Automated Cost Ingestor (Aprimorado e Conectado):**
    *   Puxa dados de receita bruta diretamente da API do Shopify (pedidos, itens de linha, descontos, impostos).
    *   **COGS:** Permite ao usuário inputar COGS por produto/variante diretamente na interface do IONFLUX (armazenado no `Data Store` do agente) ou, idealmente, puxa de campos de custo do Shopify ou de integrações com sistemas de inventário/ERP (futuro).
    *   **Transaction Fees:** Calcula automaticamente taxas de transação do Shopify Payments e outros gateways configurados (Stripe, PayPal) usando percentuais padrão ou configuráveis pelo usuário.
    *   **Shipping Costs:** Puxa custos de frete reais dos pedidos no Shopify. Permite ao usuário definir regras de custo de frete padrão se os dados não estiverem completos.
    *   **Marketing Costs (via Agentes):** **NOVO:** Integra-se com outros agentes IONFLUX (e.g., um futuro "Facebook Ads Agent" ou "Google Ads Agent", ou via dados do `Outreach Automaton`) para puxar custos de campanhas de marketing e atribuí-los aos produtos/pedidos relevantes para cálculo de ROAS e lucratividade pós-marketing. Para a versão "Lite", pode ser um input manual de "Custo de Marketing por Pedido Médio".
    *   **App Fees (Shopify):** **NOVO:** Permite ao usuário listar os custos fixos mensais de seus apps Shopify. O agente pode então amortizar esse custo por pedido para uma visão mais completa.
*   **Real-time Margin Calculator (Aprimorado `Margin Calculator`):**
    *   Calcula para cada pedido (e agrega por dia/semana/mês): Receita Bruta, Descontos, Receita Líquida, COGS Total, Taxas de Transação, Custo de Frete, (Opcional) Custo de Marketing Atribuído, (Opcional) Custo de App Amortizado.
    *   Calcula Margem de Contribuição Bruta (Receita Líquida - COGS - Taxas - Frete).
    *   Calcula Margem de Contribuição Líquida (Margem Bruta - Custos de Marketing - Custos de App).
    *   Apresenta Ponto de Equilíbrio básico (quantos pedidos/receita são necessários para cobrir custos fixos informados).
*   **Profitability Variance Sentinel (Aprimorado `Variance Sentinel`):**
    *   Monitora tendências na margem de contribuição por produto ou geral.
    *   Alerta o usuário sobre:
        *   Produtos com margem negativa ou em queda acentuada.
        *   Aumento inesperado em COGS, taxas ou custos de frete.
        *   Impacto de novas campanhas de desconto na lucratividade geral.
*   **Actionable Insights & Daily Digestor (Aprimorado `Daily Digestor`):**
    *   Fornece um resumo diário/semanal (via Slack/Email com Agente 001/007, ou no Canvas IONFLUX) com:
        *   Lucratividade total e por produto chave.
        *   Produtos mais/menos lucrativos.
        *   Alertas de variância importantes.
        *   **NOVO:** Sugestões simples baseadas em LLM (`GPT-4o`) para otimização (e.g., "Considere testar um aumento de 5% no preço do Produto Y, que tem alta demanda e margem para absorver").
*   **Data Source for Other Agents (Novo - Sinergia):**
    *   Expõe dados de lucratividade (e.g., margem por produto) via API interna para que outros agentes IONFLUX possam usá-los em suas lógicas de decisão (e.g., `Email Wizard` pode focar em emails para produtos de alta margem; `UGC Matchmaker` pode priorizar criadores para promover produtos de alta lucratividade).

### 5. Mecanismos/Tecnologias Refatorados
*   **Integração Shopify:** API Admin do Shopify (GraphQL e REST).
*   **Cálculos Financeiros:** Python (Pandas para manipulação de dados, se necessário, mas principalmente lógica de negócios direta para a versão "Lite").
*   **Geração de Insights com LLM:** `GPT-4o` (via `LLM Orchestration Service`) para as sugestões acionáveis.
*   **Armazenamento:** `PostgreSQL` para armazenar dados de pedidos processados, custos calculados, COGS inputados, e snapshots de lucratividade. `Redis` para caching de dados recentes para o dashboard.
*   **Alertas e Digest:** Integração com Agente 001 (Email) e Agente 007 (Slack/Chat Butler).

### 6. YAML de Definição (Refatorado)
```yaml
id: agent_010_refactored
name: RevenueTrackerLite_v2
version: 0.2
description: "Provides actionable insights into e-commerce store profitability by tracking revenue, variable costs, and calculating contribution margin."
triggers:
  - type: webhook # Triggered by Shopify order creation/update events (via ShopifyIntegrationService)
    path: "/revenue_tracker/shopify_event"
    config:
      workspace_id_param: "workspace_id"
      shop_id_param: "shopify_shop_id" 
  - type: schedule
    cron: "0 5 * * *" # Daily at 5 AM (user's timezone)
    config:
      task: "generate_daily_profitability_digest"
      workspace_id: "all_active_with_shopify"
inputs_schema:
  - key: shopify_order_payload # From Shopify webhook
    type: json
    required: false # Not required if trigger is schedule
    description: "Payload of a Shopify order event (created, updated)."
  - key: shopify_product_payload # For COGS updates or product list
    type: json
    required: false
    description: "Payload of Shopify product events or product list for COGS management."
  - key: manual_cost_inputs # For user to input COGS, app fees, avg marketing cost
    type: json
    required: false
    description: "JSON object allowing users to manually input or update COGS per SKU, fixed app fees, average marketing cost per order."
outputs_config:
  - key: profitability_dashboard_data_json
    type: json 
    description: "Structured JSON data for rendering a profitability dashboard (daily/weekly/monthly trends, top/bottom products by margin)."
  - key: profitability_digest_markdown
    type: md
    description: "Markdown formatted daily/weekly digest of key profitability insights and alerts."
  - key: actionable_alert_payload # For other agents or notification service
    type: json
    description: "Payload for critical profitability alerts (e.g., product margin negative)."
stack_details:
  language: python
  runtime: "FastAPI, Pandas (optional)"
  models_used:
    - "openai:gpt-4o (for generating actionable suggestions)"
  database_dependencies: ["PostgreSQL (for processed financial data, COGS)", "Redis (for caching dashboard data)"]
  queue_dependencies: ["Redis + RQ (for async report generation)"]
  other_integrations: ["Shopify Admin API", "Payment Gateway APIs (Stripe, PayPal - future for direct fee reconciliation)", "Marketing Platform APIs (future for cost ingestion)", "Agent001/007 (for digests/alerts)"]
memory_config: 
  type: none # Primarily uses structured data in PostgreSQL.
  description: "Embeddings are not core for 'Lite' version; future 'Pro' might use Pinecone for analyzing text in product descriptions vs. profitability."
```

### 7. Estrutura de Dados Refatorada
*   **PostgreSQL:**
    *   `rt_shopify_orders_processed`: `order_id (primary key)`, `workspace_id`, `shop_id`, `order_date`, `total_revenue_gross`, `total_discounts`, `total_revenue_net`, `total_cogs`, `total_transaction_fees`, `total_shipping_costs`, `total_marketing_costs_attributed (nullable)`, `total_app_fees_amortized (nullable)`, `calculated_gross_margin`, `calculated_net_margin`, `line_items_details_jsonb`.
    *   `rt_product_costs`: `product_id (primary key)`, `variant_id (primary key)`, `workspace_id`, `shop_id`, `sku`, `cogs_amount`, `manual_override (boolean)`, `last_updated`.
    *   `rt_workspace_cost_settings`: `workspace_id (primary key)`, `shop_id`, `default_transaction_fee_percent`, `average_marketing_cpo (nullable)`, `monthly_app_fees_total (nullable)`.
    *   `rt_profitability_snapshots`: `id`, `workspace_id`, `period_start_date`, `period_end_date`, `total_net_margin`, `top_profitable_products_jsonb`, `margin_alerts_jsonb`.

### 8. Stack Tecnológica Refatorada
*   **Runtime:** Python 3.12 + FastAPI.
*   **Data Handling:** Pandas (potentially for complex calculations if needed, otherwise direct SQL/Python logic).
*   **LLM:** GPT-4o (via `LLM Orchestration Service`) for insights.
*   **Databases:** PostgreSQL, Redis.
*   **Queue:** Redis + RQ.
*   **Observability:** OpenTelemetry, Prometheus, Grafana (dashboard "E-commerce Profitability Insights").

### 9. Triggers Refatorados
*   **Webhook (Primary):** Triggered by `ShopifyIntegrationService` upon new/updated Shopify orders. This allows for near real-time calculation for individual orders.
*   **Scheduled (Daily/Hourly):**
    *   Hourly: Aggregate individual order calculations into hourly trends (if needed for `Variance Sentinel`).
    *   Daily (e.g., 5 AM user's timezone): Generate `profitability_digest_markdown`, update `rt_profitability_snapshots`, check for new products needing COGS input.
*   **Manual/API Call:** User can request a recalculation or refresh of the dashboard/digest.
*   **Breaker Logic:** If API calls to Shopify fail repeatedly, or if critical cost data (like COGS for many new products) is missing preventing meaningful calculations, the agent sends an alert to the user/workspace admin to check configurations or input data.

### 10. KPIs Refatorados
*   **Core:** Accuracy of Gross & Net Contribution Margin calculation (compared to manual or accounting reports, where possible), User adoption/engagement with the profitability dashboard/digest.
*   **Value:** Number of actionable insights generated, User-reported actions taken based on agent's suggestions (qualitative feedback initially).
*   **Sistema:** Latency of order processing for profitability calculation, Shopify API call success rates.

### 11. Exemplo Integrado (Refatorado)
**Cenário:** Uma loja Shopify vende camisetas personalizadas.
1.  **Setup:** O lojista conecta sua loja Shopify. O `Revenue Tracker Lite` puxa os produtos. O lojista usa a interface do IONFLUX para inputar o COGS para cada tamanho/cor de camiseta (e.g., Camiseta Branca P: R$15 COGS). Define sua taxa de gateway (e.g., Stripe 2.9% + R$0.30) e custos médios de frete por região. Adiciona R$100/mês em custos de apps Shopify.
2.  **Pedido Entra:** Um cliente compra 2 camisetas por R$100 (+ R$10 frete). Total R$110.
    *   Webhook do Shopify é enviado para `Revenue Tracker Lite`.
3.  **Cálculo em Tempo Real:** O agente calcula:
    *   Receita Líquida: R$100 (supondo sem descontos/impostos para simplificar).
    *   COGS: R$30 (2 x R$15).
    *   Taxa Stripe: R$100 * 0.029 + R$0.30 = R$3.20.
    *   Custo Frete: R$10 (conforme pedido).
    *   Custo App Amortizado (exemplo simplificado): Se a loja tem 200 pedidos/mês, R$100/200 = R$0.50 por pedido.
    *   Margem de Contribuição Bruta (Pedido): R$100 - R$30 - R$3.20 - R$10 = R$56.80.
    *   Margem de Contribuição Líquida (Pedido, sem marketing específico aqui): R$56.80 - R$0.50 = R$56.30.
4.  **Dashboard & Digest:**
    *   O dashboard de lucratividade no IONFLUX é atualizado.
    *   No final do dia, o `Daily Digestor` envia um resumo para o Slack (via Agente 007): "Resumo de Lucratividade de Hoje: Receita Total R$X, Custo Total Variável R$Y, Margem de Contribuição Líquida R$Z. Produto mais lucrativo: Camiseta Preta G."
5.  **Alerta de Insight (Exemplo):** Após uma semana, o agente nota que o custo de frete para "Região Nordeste" aumentou 15% devido a uma mudança de tabela da transportadora, tornando os pedidos para essa região menos lucrativos. Um alerta é gerado: "Atenção: Custo de frete para Nordeste subiu 15%, impactando margem em X%. Considere revisar sua política de frete para esta região."

### 12. Expansão Dinâmica (Refatorada)
*   **V1.1 (Marketing Cost Attribution):** Integração mais profunda com plataformas de anúncios (Meta, Google) ou com agentes IONFLUX de marketing para atribuir custos de publicidade a nível de pedido/produto, calculando o ROAS e a lucratividade pós-marketing de forma mais precisa.
*   **V2.0 (What-If Scenario Modeling):** Permitir que o usuário simule o impacto de mudanças de preço, COGS, ou custos de marketing na lucratividade total e no ponto de equilíbrio (e.g., "Se eu aumentar o preço da Camiseta Branca P em 10%, qual o impacto na margem e quantas unidades preciso vender para manter o lucro atual?").

### 13. Escape do Óbvio (Refatorado)
**"Profitability Elasticity Score":** O agente não apenas rastreia a margem, mas tenta estimar a "elasticidade da lucratividade" de cada produto. Ele pode sugerir pequenos experimentos de preço (com integração ao Shopify para alterar preços temporariamente em alguns SKUs) e observar o impacto nas vendas E na margem total. Com o tempo, ele aprende quais produtos têm mais "espaço" para aumento de preço sem queda drástica nas vendas, ou quais produtos se beneficiariam de uma pequena redução de preço para ganhar volume e ainda assim aumentar o lucro total. Isso transforma o tracker de um sistema passivo para um otimizador ativo de lucratividade.

Preencha. Refine. Lance.
---
