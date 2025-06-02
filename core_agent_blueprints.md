# IONFLUX Project: Core Agent Blueprints

This document provides detailed blueprints for the 10 core agents in the IONFLUX platform, as per the project proposal and user-provided specifications.

---

## AGENTE 001 — EMAIL WIZARD / Pulse of the Inbox
“Transforma caixas de entrada em máquinas de destino”

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
*   Hyper-Segment: constrói micro-coortes em tempo real via embeddings.
*   Dopamine Drip: sequência adaptativa que lê cliques e ajusta offer.
*   Auto-Warm-Up: gera tráfego friendly para blindar reputação.
*   Predictive Clearance: deleta e-mails de baixa probabilidade antes do envio.

#### 2.2 PoolDad 22,22 %
**Punch:** “Inbox frio é mausoléu; nós acendemos a fogueira.”
**Interpretação:** afirma o caos do spam e o converte em sinal brutal.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

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
*   Runtime: Python 3.12 + FastAPI
*   Framework: LangChain + LangGraph
*   LLM: OpenAI GPT-4o (creative) / Claude (backup)
*   Vector DB: Pinecone (profiles)
*   Queue: Redis + RQ
*   ORM: SQLModel
*   Observability: OpenTelemetry → Prometheus → Grafana
*   CI/CD: GitHub Actions + Docker Buildx + Fly.io

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

### 8 ▸ Data Store
Pinecone namespace emailwizard_personas guarda embeddings crus.

### 9 ▸ Scheduling & Triggers
*   Cron primário: 0 */2 * * * → envia fila pendente.
*   Webhook: /emailwizard/run → dispara imediata.
*   Breaker: 3 falhas 500 consecutivas → pausa e alerta #ops-email.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Flash-sale relâmpago Shopify
Shopify emite webhook order/create rápido ↑ 20 % visitors.
ShopiPulse injeta evento → EmailWizard seleciona segmento “High-AOV past buyers”.
GPT-4o gera subject “⚡ 45-min Secret Flash (For Your Eyes Only)”.
Sendgrid dispara 3 200 e-mails em 45 s.
ClickSense rastreia 512 cliques → 128 checkouts ($8 400).
StripeEcho envia eventos; KPIs atualizam em Dashboard Commander.

### 13 ▸ Expansão Dinâmica
*   V1.1: Dynamic AMP e-mail (conteúdo muda pós-envio).
*   V2.0: E-mail-to-WhatsApp fallback: se não abrir 24 h, dispara mensagem snackbar.

### 14 ▸ Escape do Óbvio
Insira pixel WebRTC que detecta fuso horário real → reescreve CTA na hora da abertura (“a oferta termina em 12 min onde você está agora”). Resultado: 1.4× CTR.

Preencha. Refine. Lance.

---

## AGENTE 002 — WHATSAPP PULSE / Heartbeat of Conversations
“Transforma pings verdes em pulsares de receita”

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
*   Persona-Aware Reply: escreve em dialeto do usuário (embedding + gírias locais).
*   Smart Drip: sequência progressiva: lembrete → oferta suave → escassez → bônus.
*   Opt-in Whisper: gera links one-click, salva provas de consentimento (LGPD/GDPR).
*   Voice-Note AI: transforma script em áudio humanizado TTS para engajamento 1.6×.

#### 2.2 Essência 22,22 %
**Punch:** “Bloqueio? Só se for gatilho de FOMO.”
**Interpretação:** abraça o risco: se não vale vibrar, não vale existir.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

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
*   Runtime: Python 3.12 + FastAPI
*   Framework: LangChain + LangGraph
*   LLM: GPT-4o (creative), DeepSeek B32 (fallback)
*   Vector: Pinecone (user style embeddings)
*   Queue: Redis Streams
*   Messaging: Meta WhatsApp Cloud API
*   TTS: Azure Speech / Coqui TTS fallback
*   Observability: OpenTelemetry → Loki → Grafana

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
(No specific content provided beyond heading)

### 9 ▸ Scheduling & Triggers
*   Cron: cada 15 min roda fila de eventos pendentes.
*   Webhook: /hook recebe callback de entrega & resposta.
*   Breaker: ≥ 20 % bounce code → pausa playbook, notifica #ops-wa.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário Black Friday Abandoned Cart
Cliente adiciona R$ 750 em produtos, some.
Shopify → webhook; WhatsAppPulse detecta high AOV.
Gera mensagem voice-note + texto com cupom 8 %.
Envia às 20:10 (janela ativa região).
Cliente ouve áudio, clica link, finaliza compra.
StripeEcho lança evento; KPI Revenue/message = $1.04.
Badge Motivator dá XP ao agente.

### 13 ▸ Expansão Dinâmica
*   V1.1: Flows multi-mídia (carrossel catálogos).
*   V2.0: Chat-commerce inline (checkout dentro do chat usando WhatsApp Pay).

### 14 ▸ Escape do Óbvio
Detectar “dormência” de chat: se usuário não abre app há 72 h, enviar sticker personalizado gerado por Midjourney com nome do cliente no balão. CTR aumenta ~1.8× em testes iniciais.

Preencha. Refine. Lance.

---

## AGENTE 003 — TIKTOK STYLIST / Ritualist of the Swipe
“Vira feed frenético em desfile de persona pura”

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
*   StyleScan: analisa 30 vídeos passados e extrai fingerprint visual-verbal.
*   ClipForge: corta, recalibra ritmo, insere captions dinâmicos e zooms estratégicos.
*   SoundSynch: alinha beat com movimento/zoom para 1.3 × retenção.
*   AutoPost Oracle: calcula pico regional do público e agenda push.

#### 2.2 Essência 22,22 %
**Punch:** “Frames são lâminas: use-as ou será dilacerado pelo tédio.”
**Interpretação:** edita com crueldade estética: nada supérfluo sobrevive.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

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
*   Runtime: Python 3.12, FastAPI
*   LLM: GPT-4o (script/caption), Whisper-large (transcribe)
*   Video Processing: ffmpeg, moviepy, ffprobe
*   Trend Feed: TikTok Trend API (unofficial wrapper)
*   Vector DB: Pinecone (style embeddings)
*   Queue: Redis Streams; fallback SQS
*   Storage: S3 (+ CloudFront)
*   Observability: Prometheus + Grafana dashboard “VideoOps”

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
*   Webhook: /upload dispara pipeline end-to-end.
*   Cron: 0 */1 * * * — verifica novos sons virais e atualiza TrendBeat.
*   Breaker: > 3 uploads rejeitados → switch para revisão manual, alerta Slack.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Lançamento de coleção cápsula Shopify
Criador grava unboxing bruto (2 min).
/upload acionado pelo app mobile.
StyleScan detecta humor “excited streetwear” → ClipForge cria 18 s highlight com zoom beat-sync.
ShopTagger anexa link utm=tiktok_capsule.
Autopost publica 18:45 (pico).
TokGraph callback: 56 k views primeiro 30 min, 8.2 % CTR link.
Shopify Sales Sentinel reporta 240 vendas — mensagem Slack “🔥 Capsule sold out”.

### 13 ▸ Expansão Dinâmica
*   V1.1: Real-time AR stickers (OpenCV + Segmentation).
*   V2.0: Multilingual lip-sync (RVC voice clone + re-timing).

### 14 ▸ Escape do Óbvio
Gera dois finais alternativos e publica como “choose-your-ending” via TikTok interactive cards; coleta micro-votos que alimentam StyleScan, dobrando retenção em episódios futuros.

Preencha. Refine. Lance.

---

## AGENTE 004 — SHOPIFY SALES SENTINEL / Guardian of the Cashflow Veins
“Fiscaliza cada batida de venda — avisa antes da hemorragia”

### 0 ▸ Header Narrativo
**Epíteto:** O Vigia Que Ouve o Caixa Respirar em Tempo Real
**TAGLINE:** SE A RECEITA PISCA, O SENTINEL DISPARA

### 1 ▸ Introdução (22 linhas)
Uma loja morre primeiro no silêncio do dashboard, depois no caixa.
Você refresca o admin — nada muda; a ansiedade cresce.
Dor: tráfego alto, vendas caindo e você descobre só no relatório do dia seguinte.
Oportunidade: interceptar o sangramento nos 90 segundos após a queda de conversão.
Visão: sentinela que opera como ECG — detecta arritmia de receita.
Palavra-icônica: Pulso — receita pulsa como batimento.
Metáfora: sonar submarino captando cada ping de pedido.
Imagem: gráfico cardíaco verde; picos viram alarmes rubros ao despencar.
Estatística-punhal: 38 % dos merchants perdem +10 % GMV/ano por detecção tardia de bug no checkout.
Ruptura: relatórios diários viram alertas de minuto em minuto.
Futuro-próximo: IA prediz falha de gateway antes do suporte saber.
Fantasma-do-fracasso: campanha de tráfego pago queimando $800/h com check-out off.
Promessa-radical: nenhum pixel de venda escapa ao radar.
Cicatriz-pessoal: founder perdeu Black Friday porque app de frete bugou.
Convite-insubmisso: torne-se onipotente sobre cada carrinho.
Chave-filosófica: informação tardia é auto-sabotagem.
Eco-cultural: FOMO dos devs às 3 h da manhã.
Grito-mudo: beep-beep-beep travado.
Virada-de-jogo: auto-rollback de app que degrada conversão.
Manifesto-síntese: vigiar é amar a receita.
Pulso-de-ação: verde vivo → conversão viva.
Silêncio-ensurdecedor: gráfico flat? jamais.

**⚡ Punch final**
“Dashboard atrasado é necrotério de dados.”
“Quem detecta em horas já está morto em minutos.”
“Deixe o Sentinel dormir e acorde sem caixa.”

### 2 ▸ Essência
**Arquétipo:** Sentinel-Engineer
**Frase-DNA:** “Escuta o sussurro da venda antes do grito da falha”

#### 2.1 Principais Capacidades
*   Realtime Pulse: stream de pedidos, AOV, conversão a cada 5 s.
*   Anomaly Guardian: detecção ML (Z-score + Prophet) para drops/spikes.
*   App-Impact Radar: correlaciona instalação/update de app c/ variação de CVR.
*   Rollback Autonomo: desativa app ou tema se perda > x %.

#### 2.2 Essência 22,22 %
**Punch:** “Checkout que trava é faca no fluxo — o Sentinel a arranca.”
**Interpretação:** age brutalmente; prefere remover feature a deixar receita sangrar.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_004
name: ShopifySalesSentinel
version: 0.1
triggers:
  - type: schedule
    cron: "*/5 * * * *"
  - type: webhook
    path: "/sentinel/event"
inputs:
  - key: shopify_event
    type: json
    required: false
  - key: latency_log
    type: json
    required: false
outputs:
  - key: incident_report
    type: md
stack:
  language: python
  runtime: fastapi
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: sentinel_rootcause
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Stream: Kafka (Confluent) topic shop-orders
*   Anomaly: Facebook Prophet + Z-score custom
*   Vector: Pinecone (incident embeddings)
*   DB: Postgres (orders cache 24 h)
*   Queue: RQ (critical actions)
*   Infra: Docker + Fly.io autoscale
*   Observability: Prometheus exporter + Grafana “SalesPulse”

### 7 ▸ Files & Paths
```
/agents/sales_sentinel/
  ├── agent.py
  ├── anomaly.py
  ├── rootcause.py
  ├── actions.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_anomaly.py
  └── assets/
      └── backup/
          └── theme.zip
```

### 8 ▸ Data Store
Vector namespace sentinel_incidents para explicações LLM.

### 9 ▸ Scheduling & Triggers
*   Cron 5 min: roll-up + forecast update.
*   Webhook: recebe cada evento e enfileira.
*   Breaker: se 3 incidentes críticos/1 h → eleva para pager-duty.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: App de desconto 3rd-party bugou checkout
Spike 502 no gateway → CVR despenca de 3.2 %→0.4 %.
Angle Δ-3σ detectado em 80 s.
Rootcause matches app update 5 min antes.
Sentinel usa appDisable via GraphQL, publica incident doc no Notion.
CVR volta a 3 % em 7 min.
SlackSiren posta “🛡️ checkout normalized; GMV saved est. $4 700”.

### 13 ▸ Expansão Dinâmica
*   V1.1: LLM Root-Cause chat: conversa sobre incidente, sugere fix patches.
*   V2.0: Cross-store comparative baseline (benchmark entre merchants).

### 14 ▸ Escape do Óbvio
Se CVR sobe +120 % em 2 min (bot ataque), Sentinel ativa “honeypot checkout” para filtrar fraudadores antes de afetar estoque real.

Preencha. Refine. Lance.

---

## AGENTE 005 — UGC MATCHMAKER / Brand-Creator Oracle
“Encontra o DNA perdido entre briefing e feed”

### 0 ▸ Header Narrativo
**Epíteto:** O Oráculo que Costura Marcas ao Sangue dos Criadores
**TAGLINE:** NÃO EXISTE BRIEFING SEM ALMA: NÓS OUVIMOS A BATIDA

### 1 ▸ Introdução (22 linhas)
Centenas de marcas gritam; milhões de criadores ecoam — e ninguém se escuta.
Feed saturado, DM lotada, propostas genéricas apodrecendo no inbox.
Dor: gastar verba com influenciador que não converte — casamento sem química.
Oportunidade: alinhar tom, estética e público em questão de segundos.
Visão: algoritmo que cheira o “cheiro” de uma marca e fareja o criador compatível.
Palavra-icônica: Imprint — marca invisível na pele da audiência.
Metáfora: radar bioquímico buscando chave-fechadura entre voz e produto.
Imagem: gráfico de embeddings colapsando num ponto luminoso de afinidade 0.97.
Estatística-punhal: 61 % dos collabs falham por mismatch de valores (Shopify/BRC 2024).
Ruptura: brief anonymizado evita viés e garante matches sinceros; nomes revelados só após compatibilidade ≥ 0.8.
Futuro-próximo: marca negocia com agente-IA do criador antes de DM humana.
Fantasma-do-fracasso: vídeos lindos, CTR pífio e ROI negativo.
Promessa-radical: cada collab nasce pré-aprovada pela afinidade de estilo, voz e valor.
Cicatriz-pessoal: creator “clean beauty” cancelado após collab com energética.
Convite-insubmisso: vire cupido algorítmico, não caça-inbox desesperado.
Chave-filosófica: autenticidade não se compra — se reconhece.
Eco-cultural: fandom reage a falsidade mais rápido que algoritmo.
Grito-mudo: “isso não parece você”.
Virada-de-jogo: KPI = clap-rate (likes + saves por mil).
Manifesto-síntese: colaborações que soam inevitáveis.
Pulso-de-ação: swipe, DM, contrato — sem fricção.
Silêncio-ensurdecedor: feed vibra de naturalidade — ninguém percebe a máquina por trás.

**⚡ Punch final**
“Publicidade morta fede; matchmaking vivo perfuma o feed.”
“Brand lift sem afinidade é levantar peso com braço quebrado.”
“Criador errado custa mais que campanha fracassada: custa reputação.”

### 2 ▸ Essência
**Arquétipo:** Hermes-Connector
**Frase-DNA:** “Traduz briefing em pulsação humana”

#### 2.1 Principais Capacidades
*   Brief2Vector: transforma briefing em embedding semântico-emocional.
*   PersonaProbe: gera embedding de criador via transcrição, coloração de fala, paleta visual.
*   AffinityMatrix: cálculo cosine + heurísticas culturais (regionais, ética, valores).
*   GhostPitch: redige proposta personalizada e envia via Slack/E-mail/WhatsApp.

#### 2.2 Essência 22,22 %
**Punch:** “Cupido digital não erra flecha; quem erra flecha não merece arco.”
**Interpretação:** combina rigor matemático com intuição poética.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_005
name: UGCMatchmaker
version: 0.1
triggers:
  - type: webhook
    path: "/ugc/match"
inputs:
  - key: brief_id
    type: string
    required: true
outputs:
  - key: match_table
    type: md
stack:
  language: python
  runtime: langchain
  models:
    - openai:text-embedding-3-small
    - openai:gpt-4o
    - clip:openai
memory:
  type: pinecone
  namespace: ugc_matchmaker
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM / Embeds: OpenAI (text + image), Whisper v3
*   Vector: Pinecone (1536 dim)
*   ML: Scikit-learn (PCA heuristics)
*   Scraping: Playwright headless, yt-dLP
*   Queue: Celery + Redis
*   Observability: OpenTelemetry → Grafana Loki
*   Storage: Postgres (briefings, matches, consents)

### 7 ▸ Files & Paths
```
/agents/ugc_matchmaker/
  ├── agent.py
  ├── brief2vec.py
  ├── persona_probe.py
  ├── affinity.py
  ├── ghost_pitch.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_affinity.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
Namespace ugc_vectors. 10 M embeddings capacity.

### 9 ▸ Scheduling & Triggers
*   Webhook: POST /ugc/match com brief_id.
*   Cron 12 h: refresh creator stats + embeddings.
*   Breaker: se ≥ 3 pitches rejeitados seguidos → agrega feedback, re-treina prompt.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Marca de skincare clean quer criador 25-35 PT-BR
PM cria Brief Notion com keywords “clean beauty”, “pele sensível”.
/ugc/match brief_id=abc123 dispara pipeline.
Brief2Vector gera embedding; PersonaProbe atualiza 12k creators.
AffinityMatrix retorna top 7 (score 0.83-0.92).
GhostPitch cria proposta: R$ 1 500 + 2 Reels + UGC fotos em 10 d.
SlackPitch envia DM — criador top aceita em 6 min.
ConsentVault armazena opt-in; contrato DocuSign criado.

### 13 ▸ Expansão Dinâmica
*   V1.1: Resumir briefing por voz (OpenAI Audio).
*   V2.0: Marketplace “auction mode” onde criadores dão lances de proposta.

### 14 ▸ Escape do Óbvio
Usa sentiment inversion: se brand quer “seriedade clínica”, sistema sugere criador com 30 % contraste humorístico — A/B mostra 2.1× CTR porque quebra expectativa.

Preencha. Refine. Lance.

---

## AGENTE 006 — OUTREACH AUTOMATON / Hunter of the Untapped Inboxes
“Rastreia leads no escuro, soma contexto e dispara oferta cirúrgica”

### 0 ▸ Header Narrativo
**Epíteto:** O Predador que Fareja Vendas em Bancos de Dados Mortos
**TAGLINE:** LEAD FRIO É LENHA: NÓS INCENDEMOS RESULTADO

### 1 ▸ Introdução (22 linhas)
Milhões de e-mails congelam em planilhas que ninguém abre.
Todo dia, mais nomes entram no cemitério de CRM sem toque humano.
Dor: pipeline entupido, quota batendo na porta, time batendo cabeça.
Oportunidade: IA que caça contexto, fabrica relevância e derruba porta fechada.
Visão: cada lead vira micro-campanha hiperespecífica em 45 segundos.
Palavra-icônica: Sonda — fura a crosta de dados duros e encontra magma quente.
Metáfora: satélite rastreando calor corporal no deserto noturno.
Imagem: score vermelho acendendo em mapa 3D de prospects.
Estatística-punhal: SDR médio gasta 63 % do tempo só pesquisando lead (Gartner 2025).
Ruptura: pesquisa vira crônometro de 400 ms; contato produz resposta em 14 min.
Futuro-próximo: cadência multicanal auto-mutante conforme horário on-line do prospect.
Fantasma-do-fracasso: VP vendas pergunta pipeline; você só tem pressa e PowerPoint.
Promessa-radical: 60 emails personalizados/h sem levantar da cadeira.
Cicatriz-pessoal: time sofreu burn-out durante Black Friday; envios manuais falharam.
Convite-insubmisso: deixe a máquina suar; você fica com a comissão.
Chave-filosófica: relevância não é arte — é cálculo íntimo.
Eco-cultural: ninguém quer “Oi, tudo bem?” genérico em 2025.
Grito-mudo: inbox apitando com thread de resposta.
Virada-de-jogo: ligação auto-gerada marcada só quando prospect abre quinto e-mail.
Manifesto-síntese: cold-email morreu; viva o Context Outreach.
Pulso-de-ação: tecla “Run” = chuva de reuniões.
Silêncio-ensurdecedor: quota batida antes da 3.ª xícara de café.

**⚡ Punch final**
“Prospect que não responde é alguém que você não entendeu.”
“Pesquisa manual é luxo de 2010.”
“Se sua cadência não muda, seu spam faz morada.”

### 2 ▸ Essência
**Arquétipo:** Hunter-Strategist
**Frase-DNA:** “Transforma lista crua em pipeline respirando”

#### 2.1 Principais Capacidades
*   DataMiner Scraper: coleta perfil LinkedIn, loja Shopify, métricas Similarweb.
*   ContextForge: gera “hook” de abertura baseado em evento (funding, post viral, press).
*   Multi-Cadence Drip: orquestra e-mail → LinkedIn DM → WhatsApp.
*   Auto-Booker: conecta Calendly, marca call quando reply contém “vamos falar”.

#### 2.2 Essência 22,22 %
**Punch:** “Lead gelado, alma quente: o fogo vem do contexto.”
**Interpretação:** a máquina usa o excesso de dado para esculpir copy que parece feita à mão.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_006
name: OutreachAutomaton
version: 0.1
triggers:
  - type: webhook
    path: "/outreach/kickoff"
inputs:
  - key: list_url
    type: string
    required: true
  - key: icp_profile
    type: json
    required: true
outputs:
  - key: outreach_report
    type: md
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: outreach_ctx
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o (copy), GPT-3.5 turbo (variant)
*   Scraping: Playwright cluster (Stealth)
*   Vector: Pinecone (hooks library)
*   Queue: Redis Streams → RQ workers
*   DB: Postgres (lead, touchpoints)
*   Observability: OpenTelemetry, Jaeger trace
*   CI/CD: GitHub Actions, Docker, Railway

### 7 ▸ Files & Paths
```
/agents/outreach_automaton/
  ├── agent.py
  ├── dataminer.py
  ├── contextforge.py
  ├── cadence.py
  ├── prompts.yaml
  ├── linkedin_bot.js
  ├── tests/
  │   ├── test_context.py
  │   └── test_cadence.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Pinecone namespace outreach_hooks.

### 9 ▸ Scheduling & Triggers
*   Webhook Kickoff: /outreach/kickoff com URL da lista.
*   Cadence Cron: */10 * * * * dispara toques pending.
*   Breaker: bounce > 5 % ou spamflag > 0.3 % → pausa lista + alerta.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Listar top 100 lojas Shopify de decoração → vender app UGC
list_url=gs://bucket/decoration_top100.csv dispara webhook.
DataMiner coleta site data, LinkedIn founders, funding.
ContextForge identifica que 27 lojas postaram Reels de user photos.
GPT-4o gera copy citando post “insta/8492” → Sent “Hey Ana, vi seu Reels de ontem…”.
LinkedDM envia na conta SDR; SendGrid backup.
14 respostas; 7 reuniões auto-agendadas Calendly.
CRMBridge cria deals; KPIs green.

### 13 ▸ Expansão Dinâmica
*   V1.1: Voice note outbound via Twilio < 30 s AI-cloned voz.
*   V2.0: Auto-pricing: propõe fee baseado em funding round + GMV scraping.

### 14 ▸ Escape do Óbvio
“Re-anima leads mortos”: Script busca domínios sem posts novos 6 m, sugere email ‘revival’ oferecendo parceria que reativa audience — teste piloto gerou 18 % de retorno latent.

Preencha. Refine. Lance.

---

## AGENTE 007 — SLACK BRIEF BUTLER / Concierge of Lightning Alignment
“Serve resumos brutais antes que o ruído invada a mente”

### 0 ▸ Header Narrativo
**Epíteto:** O Mordomo que Organiza o Caos em Mensagens de 90 Segundos
**TAGLINE:** SE NÃO CABE NUM SLACK, NÃO MERECE EXISTIR

### 1 ▸ Introdução (22 linhas)
Reuniões roubam horas; briefs mal escritos roubam semanas.
Toda equipe afoga-se em threads, emojis e GIFs.
Dor: ninguém sabe quem decide — e o prazo evapora.
Oportunidade: um mordomo digital que destila ruído em ação.
Visão: cada canal acorda com sumário digerível + próximos passos claros.
Palavra-icônica: Prata — a bandeja onde chega a informação.
Metáfora: maître servindo shots de foco antes do expediente.
Imagem: feed Slack amanhece com blocos verdes “✔ Done”, laranjas “⚠ Wait”.
Estatística-punhal: 64 % dos atrasos nascem de brief incompleto (PMI 2024).
Ruptura: adeus stand-up de 15 min; olá áudio de 45 s + botões aprovação.
Futuro-próximo: briefs viram loops de IA que escutam, ajustam, confirmam.
Fantasma-do-fracasso: designer confunde rascunho v3 com final, lança bug.
Promessa-radical: 0 ambiguidade -- ou mensagem de alerta explode em vermelho.
Cicatriz-pessoal: time shipping meia-noite, refazendo banner errado.
Convite-insubmisso: compressão bruta de contexto — ou silêncio.
Chave-filosófica: informação sem hierarquia é entropia.
Eco-cultural: Slack fatigue vira piada amarga nos memes dev.
Grito-mudo: “onde está o doc?!”.
Virada-de-jogo: bot digere PDF, converte em checklist clicável.
Manifesto-síntese: quem controla o brief controla o destino do sprint.
Pulso-de-ação: abrir canal, ler 10 linhas, saber exatamente o próximo passo.
Silêncio-ensurdecedor: ninguém pergunta “o que falta?”, todos agem.

**⚡ Punch final**
“Brief longo é preguiça disfarçada.”
“Quem repete pergunta mata prazo.”
“Foco servido em bandeja — ou caos servido frio.”

### 2 ▸ Essência
**Arquétipo:** Butler-Strategist
**Frase-DNA:** “Destila informação, injeta decisão”

#### 2.1 Principais Capacidades
*   Thread Siphon: varre canais, extrai decisões, blockers, deadlines.
*   One-Click Approve: gera botões ✅/❌; registra no Notion + Jira.
*   Briefcast Audio: transforma resumo em áudio de 45 s (TTS) para mobile.
*   Stakeholder Ping: alerta pessoa-chave só quando ação requerida.

#### 2.2 Essência 22,22 %
**Punch:** “Equipes não quebram por falta de talento, mas por excesso de ruído.”
**Interpretação:** o mordomo silencia a cacofonia, serve clareza afiada.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_007
name: SlackBriefButler
version: 0.1
triggers:
  - type: schedule
    cron: "0 8 * * *"
  - type: webhook
    path: "/briefbutler/event"
inputs:
  - key: slack_event
    type: json
    required: false
outputs:
  - key: daily_brief_url
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: brief_butler
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o
*   Vector: Pinecone (thread embeddings)
*   Messaging: Slack Bolt SDK & Socket Mode
*   TTS: Azure / ElevenLabs fallback
*   DB: Postgres (decision log)
*   Observability: Prometheus + Grafana panel “BriefOps”
*   CI/CD: GitHub Actions → Fly.io rolling deploy

### 7 ▸ Files & Paths
```
/agents/brief_butler/
  ├── agent.py
  ├── thread_siphon.py
  ├── summarizer.py
  ├── tts.py
  ├── integrations/
  │   ├── notion.py
  │   └── jira.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_summary.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Namespace butler_threads.

### 9 ▸ Scheduling & Triggers
*   Cron 08:00 UTC: gera brief diário por canal tag #squad-*.
*   Webhook: evento Slack new file or high-priority tag triggers mini-brief.
*   Breaker: se reply thread > 500 msgs sem resumo → alerta.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Sprint Monday Kick-off
08:00 cron: Butler varre #squad-checkout.
Siphon classifica: 3 decisões, 1 blocker, 2 FYI.
GPT-4o gera bullets:
“Deploy v2 banner hoje 17 h (owner @aléx)✅?”
“Bug #231 still open — @diana precisa fix até 14 h.”
Slack mensagem com botões ✅/❌; @alex aceita, @diana comenta “on it”.
Notion page “2025-06-03 Brief” criado com log.
Audio 43 s gerado; mobile users ouvem correndo no café.
JiraHook move bug #231 para In Progress.

### 13 ▸ Expansão Dinâmica
*   V1.1: Auto-retro: sexta-feira, Butler compila vitórias + lições.
*   V2.0: Mode “Battle Silence”: se ruído > x, suprime notificações e manda digest.

### 14 ▸ Escape do Óbvio
Integra “emoji intel”: Butler analisa quais emojis dominam canal; se ⚰️, 😡 predominam, sinaliza toxicidade e sugere pausa de cooldown — recupera moral antes que sprint colapse.

Preencha. Refine. Lance.

---

## AGENTE 008 — CREATOR PERSONA GUARDIAN / Custodian of Authentic Voice
“Protege a assinatura invisível que faz o público dizer: ‘isso é totalmente você’”

### 0 ▸ Header Narrativo
**Epíteto:** O Guardião que Reconhece a Alma em Cada Sílaba
**TAGLINE:** VOCÊ PODE TER 1 000 AGENTES; SÓ EXISTE UMA VOZ

### 1 ▸ Introdução (22 linhas)
Seus vídeos podem mudar de formato; sua voz não pode vacilar.
Cada tropeço de tom arranha a confiança construída a sangue.
Dor: o feed denuncia quando o criador parece marketing disfarçado.
Oportunidade: IA que mapeia, aprende e defende sua identidade verbal-visual.
Visão: nenhum texto, corte ou emoji sai sem DNA verificado.
Palavra-icônica: Impressão — digital de estilo que não se copia.
Metáfora: cão de guarda linguístico farejando falsificações.
Imagem: fingerprint colorida sobreposto ao roteiro aprovado.
Estatística-punhal: 47 % dos unfollows ocorrem após “mudança estranha de tom” (Meta Creators 2024).
Ruptura: persona não é branding fixo — é organismo evolutivo, mas coeso.
Futuro-próximo: multi-LLM escrevendo em sincronia sem ruído de estilo.
Fantasma-do-fracasso: ghostwriter genérico transformando voz ácida em texto neutro.
Promessa-radical: cada palavra soa como se você mesmo tivesse digitado — e numa manhã inspirada.
Cicatriz-pessoal: criador viral cancelado por tweet fora de tom em 2019.
Convite-insubmisso: torne sua autenticidade à prova de escalas e delegações.
Chave-filosófica: estilo não se impõe; emerge — mas precisa de sentinela.
Eco-cultural: fandom celebra consistência, crucifica incoerência.
Grito-mudo: “parece chatGPT!”
Virada-de-jogo: embutir emojis-assinatura mapeados estatisticamente.
Manifesto-síntese: a voz é seu patente invisível.
Pulso-de-ação: aprovar copy vira prazer, não medo.
Silêncio-ensurdecedor: buzz de engajamento sem notar a máquina.

**⚡ Punch final**
“Autenticidade não escala — até agora.”
“Algoritmo ama voz única; nós blindamos a sua.”
“Parecer IA é falhar; soar você é fatal.”

### 2 ▸ Essência
**Arquétipo:** Guardian-Craftsman
**Frase-DNA:** “Faz a voz sobreviver à automação”

#### 2.1 Principais Capacidades
*   Signature Extractor: treina embedding 360° (léxico, ritmo, emoji, cor).
*   Tone Validator: avalia texto/roteiro/copy → score de autenticidade 0-1.
*   Style Repair: reescreve passagens fora de tom, preserva conteúdo factual.
*   Evolution Monitor: detecta drift desejado (novo arco) vs. desvio incoerente.

#### 2.2 Essência 22,22 %
**Punch:** “Plágio de si mesmo é o suicídio do criador; nós prevenimos.”
**Interpretação:** foca na linha tênue entre evolução e descaracterização.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_008
name: CreatorPersonaGuardian
version: 0.1
triggers:
  - type: webhook
    path: "/persona/validate"
inputs:
  - key: asset_url
    type: string
    required: true
  - key: creator_id
    type: string
    required: true
outputs:
  - key: validation_score
    type: float
  - key: repaired_asset_url
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - sentence-transformers:multi-qa
memory:
  type: pinecone
  namespace: persona_guardian
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o (rewrite), Sentence-Transformers (similarity).
*   Vector DB: Pinecone (persona fingerprints).
*   Multimodal: OpenAI Vision, CLIP (thumbnail style).
*   Audio: Whisper large (transcribe).
*   Queue: Celery + Redis.
*   Observability: Prometheus, Grafana persona-drift panel.

### 7 ▸ Files & Paths
```
/agents/persona_guardian/
  ├── agent.py
  ├── extractor.py
  ├── validator.py
  ├── repair.py
  ├── prompts/
  │   └── rewrite_persona.yaml
  ├── tests/
  │   ├── test_similarity.py
  │   └── test_repair.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
(No specific content provided beyond heading)

### 9 ▸ Scheduling & Triggers
*   Webhook: /validate executa em novo asset.
*   Cron semanal: verifica drift longo (> 0.15) → sugere workshop de redefinição.
*   Breaker: score médio < 0.7 → alerta Dashboard Commander.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Novo roteiro Reels escrito por Copy Assassin
Copy Assassin gera script 30 s.
/persona/validate enviado.
Validator score 0.78 (abaixo threshold) — detecta ausência de sarcasmo característico.
RepairLLM reescreve 3 frases, adiciona emoji assinatura 🙃.
Novo score 0.93; aprovado, enviado ao TikTok Stylist.
SlackPing notifica “🛡️ Voice preserved” a PM.

### 13 ▸ Expansão Dinâmica
*   V1.1: Real-time co-writing: Guardian comenta linha-a-linha no editor do criador.
*   V2.0: Marketplace de “Voice Capsules” — criadores podem licenciar style para sub-brands.

### 14 ▸ Escape do Óbvio
Embute watermark imperceptível de ritmo (quebra de linha + emoji padrão) para detectar se outra conta clona seu texto — e dispara DMCA auto.

Preencha. Refine. Lance.

---

## AGENTE 009 — BADGE MOTIVATOR / Gamemaster of Relentless Progress
“Reconfigura o vício humano em loop de entrega brutal”

### 0 ▸ Header Narrativo
**Epíteto:** O Arquiteto que Injeta Dopamina nos Marcos Invisíveis
**TAGLINE:** CADA CLIQUE VIRA XP — CADA ENTREGÁVEL, GLÓRIA

### 1 ▸ Introdução (22 linhas)
Os usuários não abandonam apps — eles abandonam sensações.
Quando o progresso se faz invisível, o cérebro troca de estímulo.
Dor: roadmap infinito, motivação zero; criador some por semanas.
Oportunidade: transformar tarefas rotineiras em microvitórias químicas.
Visão: ciclos de recompensas que premiam ação real, não vanity metrics.
Palavra-icônica: Insígnia — símbolo tangível de evolução íntima.
Metáfora: academia para a disciplina digital — pesos viram badges.
Imagem: barra de XP enchendo na cor da marca a cada publicação.
Estatística-punhal: retenção ↑ 28 % quando gamificação mostra progresso diário (Amplitude 2024).
Ruptura: badges configurados por IA, personalizados por estilo cognitivo.
Futuro-próximo: ranking de times de agentes competindo por ROI real.
Fantasma-do-fracasso: feed de analytics vazio — ninguém comemora lucro.
Promessa-radical: dopamina programada, procrastinação extinta.
Cicatriz-pessoal: criador largou curso online no módulo 3 — sem feedback, sem gás.
Convite-insubmisso: viciar-se em progresso tangível, não em rolagem infinita.
Chave-filosófica: recompensa sem conquista é ruído; conquista sem recompensa é entropia.
Eco-cultural: geração XP entende status como moeda.
Grito-mudo: “levante-se, publique, suba de nível!”
Virada-de-jogo: XP atribuído também a agentes — IA luta por prestígio.
Manifesto-síntese: trabalho é jogo; ganhar é entregar valor.
Pulso-de-ação: check-in diário, badge semanal, troféu mensal.
Silêncio-ensurdecedor: feed vibra com fogos confete — e você quer mais.

**⚡ Punch final**
“Quem não mede, esquece; quem não celebra, desiste.”
“Progresso invisível é assassinato silencioso.”
“Transforme disciplina em recompensa ou prepare-se para a estagnação.”

### 2 ▸ Essência
**Arquétipo:** Alquimista-Motivador
**Frase-DNA:** “Converte esforço em status — miligrama por miligrama”

#### 2.1 Principais Capacidades
*   XP Engine: atribui pontos a qualquer evento mensurável.
*   Badge Forge: gera insígnias SVG on-the-fly com IA design.
*   Leaderboard Pulse: ranqueia humanos e agentes em mesma tabela.
*   Reward Router: dispara webhooks (cupom, unlock feature) quando tier up.

#### 2.2 Essência 22,22 %
**Punch:** “Sem troféu não há lenda; sem lenda não há sequência.”
**Interpretação:** o mundo se move a histórias de conquista; o agente cria capítulos.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_009
name: BadgeMotivator
version: 0.1
triggers:
  - type: webhook
    path: "/xp/event"
  - type: schedule
    cron: "0 */1 * * *"
inputs:
  - key: event_payload
    type: json
    required: true
outputs:
  - key: xp_log
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: badge_motivator
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Queue: Kafka (events) + Celery (rewards)
*   Graphics: Pillow + SVGwrite for badges
*   LLM: GPT-4o (badge names, flavor text)
*   Data: Postgres (xp, badges), Redis sorted set (leaderboard)
*   Observability: Prometheus metrics xp_awarded_total, Grafana panel
*   CDN: Cloudflare R2 for badge assets

### 7 ▸ Files & Paths
```
/agents/badge_motivator/
  ├── agent.py
  ├── xp_engine.py
  ├── badge_forge.py
  ├── reward_router.py
  ├── prompts/badge_names.yaml
  ├── tests/
  │   └── test_xp_engine.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Vector namespace não exigido; tracking factual.

### 9 ▸ Scheduling & Triggers
*   Webhook: /xp/event recebe cada ação.
*   Cron hourly: puxa streak; se 24 h sem XP, envia nudge.
*   Breaker: fraude XP (> 1000/h) → flag e bloqueia.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Maratona de Conteúdo Semana Black Friday
TikTok Stylist publica 5 vídeos/dia — cada video_posted = +20 XP.
Outreach Automaton fecha 3 parcerias — deal_closed +50 XP cada.
BadgeMotivator detecta 500 XP, forja badge “Sprint Slayer”.
SlackGlow posta imagem + copy “🔥 Nível 12 alcançado”.
RewardZap gera cupom interno “50 % custo app” desbloqueado.
LeaderSync move criador para #1 do mês; dashboard mostra fogos.

### 13 ▸ Expansão Dinâmica
*   V1.1: Holographic badges AR (WebXR) para share no stories.
*   V2.0: Tokenização Web3: badges viram NFTs de reputação (Soulbound).

### 14 ▸ Escape do Óbvio
Badge “Phoenix”: só pode ser ganho após 3 quedas de streak seguidas e retomada de 7 dias — transformando falha em motivação de retorno. Resultado em teste AB: +12 % reativação usuários churn.

Preencha. Refine. Lance.

---

## AGENTE 010 — REVENUE TRACKER LITE / Ledger of the Hidden Margin
“Converte números dispersos em lucidez financeira diária”

### 0 ▸ Header Narrativo
**Epíteto:** O Contador que Sussurra Lucro Antes do Café da Manhã
**TAGLINE:** SE VOCÊ NÃO VÊ O LUCRO HOJE, ELE JÁ É PASSADO

### 1 ▸ Introdução (22 linhas)
Faturar muito não significa ganhar bem.
A planilha chega tarde; a margem some cedo.
Dor: vender, vender, vender — e ainda fechar o mês no vermelho.
Oportunidade: enxergar custo, taxa e lucro bruto em tempo real.
Visão: painel diário que mostra lucro líquido como batimento cardíaco.
Palavra-icônica: Veia — fluxo vital do caixa.
Metáfora: tomografia financeira revelando pequenos sangramentos ocultos.
Imagem: gráfico burn-down invertido — custo despencando, lucro subindo.
Estatística-punhal: 72 % dos e-commerces subestimam COGS em > 12 % (Shopify Retention 2025).
Ruptura: chega de contabilidade trimestral; nasce a contabilidade contínua.
Futuro-próximo: A-lerta push ao detectar margem < 15 % em qualquer SKU.
Fantasma-do-fracasso: descobrir taxa inesperada do app só após auditoria.
Promessa-radical: cada centavo rastreado; nenhum despesa surpresa.
Cicatriz-pessoal: fundador fechou loja porque lucro foi ilusão contábil.
Convite-insubmisso: pare de pilotar às cegas — acenda o HUD financeiro.
Chave-filosófica: só controla quem conhece — e quem mede governa.
Eco-cultural: “growth at all costs” está morto; viva “lucro com consciência”.
Grito-mudo: onde foi parar o dinheiro?
Virada-de-jogo: reconciliar Stripe, PayPal, taxas Meta Ads automaticamente.
Manifesto-síntese: faturamento é vaidade, lucro é oxigênio.
Pulso-de-ação: ping diário no Slack — “lucro de hoje: R$ 4 312”.
Silêncio-ensurdecedor: dashboard todo verde; founder dorme.

**⚡ Punch final**
“Quem não rastreia margem, assina sua certidão de óbito."
“Faturamento compra manchete; lucro compra liberdade.”
“Dinheiro não some — é você que fecha os olhos.”

### 2 ▸ Essência
**Arquétipo:** Analyst-Guardian
**Frase-DNA:** “Mostra o sangue financeiro antes que o organismo colapse”

#### 2.1 Principais Capacidades
*   Cost Ingestor: puxa COGS, frete, taxas de apps, mídia paga.
*   Margin Calculator: faz P&L incremental hora-a-hora.
*   Variance Sentinel: detecta spikes de custo ou queda de AOV.
*   Daily Digestor: resumo Slack/WhatsApp + gráficos compactos.

#### 2.2 Essência 22,22 %
**Punch:** “Lucro não é opinião; é pulso. Nós medimos ou desligamos o suporte.”
**Interpretação:** pressão brutal: sem margem saudável, outras iniciativas param.

### 3 ▸ IPO Flow (Input ▸ Processing ▸ Output)
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição (esqueleto)
```yaml
id: agent_010
name: RevenueTrackerLite
version: 0.1
triggers:
  - type: schedule
    cron: "0 * * * *"        # hora em hora
  - type: webhook
    path: "/revenue/event"   # new order
inputs:
  - key: shopify_order
    type: json
    required: false
outputs:
  - key: pnl_dashboard
    type: json
stack:
  language: python
  runtime: fastapi
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: revenue_tracker
```

### 6 ▸ Stack & APIs
(No specific content provided beyond heading)

### 7 ▸ Files & Paths
```
/agents/revenue_tracker/
  ├── agent.py
  ├── etl/
  │   ├── shopify.py
  │   ├── stripe.py
  │   ├── ads.py
  │   └── app_fees.py
  ├── pnl.py
  ├── variance.py
  ├── prompts/
  │   └── explain.yaml
  ├── tests/
  │   ├── test_pnl.py
  │   └── test_variance.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Postgres
Vector (Pinecone)
Namespace revenue_explanations (embeddings de anomalias + root-cause comments).

### 9 ▸ Scheduling & Triggers
*   Cron Hora em Hora: recalcula P&L + envia digest se GMT-3 08 h/20 h.
*   Webhook: novo pedido → atualiza linha em 10 s.
*   Breaker: saldo Stripe negativo por 2 ciclos → alerta #finance-critical.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Ads explodem custo sem conversão.
MetaSpend injeta gasto R$ 2 000 nas últimas 2 h; pedidos só R$ 500.
Variance Sentinel detecta ROAS < 0,5 drop.
Tracker puxa campanha culpada, calcula perda estimada R$ 350/h.
SlackDigest posta bloco vermelho “⚠ ROAS crítico campanha #X”.
Outreach Automaton pausa campanha via Ads API (webhook).
Margem líquida volta a 22 % no próximo ciclo.

### 13 ▸ Expansão Dinâmica
*   V1.1: cash-flow forecast 30 dias (sazonalidade).
*   V2.0: margem por canal (TikTok Shop, Mercado Livre) + recomendações.

### 14 ▸ Escape do Óbvio
Integra “Lucro Fantasma”: compara custos ocultos (tempo criador × valor hora) e mostra “Lucro Real”. Scare-metric força otimização operacional — teste piloto reduziu horas perdidas em 18 %.

Preencha. Refine. Lance.

---
```
