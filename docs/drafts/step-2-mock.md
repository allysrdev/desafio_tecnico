# Step 2 - Fundação

## Contexto

- Seguindo decisão de mockar injeção de dados

## O que foi implementado

- WCore.Machines.Machine - Struct tipada representando uma máquina
- WCore.Machines.Simulator - GenServer que simula mudanças de estado a cada 2s
- WCoreWeb.DashboardLive - LiveView que escuta o PubSub e reage à mudanças
- Highlight visual para a máquina que acabou de mudar de estado

## Fluxo

[Simulator (GenServer)]
|
| Process.send_after(self(), :tick, 2000)
v
handle_info(:tick)
|
|-- atualiza máquina aleatória na lista de estado interno
|
|-- Phoenix.PubSub.broadcast("machines:updates", {:machines_updated, machines})
|
v
[DashboardLive (todos os sockets inscritos)]
|
handle_info({:machines_updated, machines})
|
|-- find_changed_machine/2 → descobre qual mudou
|-- assign(machines, summary, highlighted_id)
|-- Process.send_after(self(), :clear_highlight, 1500)
v
re-render (somente o diff via morphdom)

## Machine.ex - Struct (contrado de dados)

- Equivalente a uma interface Machine {} em Typescript, o @type t cumpre o mesmo papel.
- Diferença: Structs são imutáveis, você sempre cria uma versão nova do dado:
  Elixir — cria nova struct com status atualizado
  %{machine | status: :error, last_updated: DateTime.utc_now()}

  Equivalente em React/TS (imutabilidade por convenção)
  { ...machine, status: "error", lastUpdated: new Date() }

## Simulator.ex — GenServer como `setInterval` do servidor

### A comparação direta com React

| Conceito React/JS              | Equivalente Elixir                                 |
| ------------------------------ | -------------------------------------------------- |
| `setInterval(fn, 2000)`        | `Process.send_after(self(), :tick, 2000)`          |
| `useState(machines)`           | Estado interno do GenServer (`machines` no `init`) |
| `setState(newMachines)`        | `{:noreply, updated_machines}`                     |
| `useEffect` cleanup            | Não necessário — processo morre e para sozinho     |
| `export function listMachines` | `def list_machines` (API pública)                  |

### Decisão tomada a partir de mentoria com IA: Por que `Process.send_after` em vez de `:timer.send_interval`?

Opção descartada:

```elixir
# Roda a cada 2s independente de quanto handle_info demorou
:timer.send_interval(2_000, :tick)
```

Opção escolhida:

```elixir
defp schedule_tick do
  Process.send_after(self(), :tick, @interval)
end

# chamado no final de handle_info(:tick, ...)
```

**Por quê:** `Process.send_after` só agenda o próximo tick
_após o atual terminar_. Isso evita que ticks se acumulem
na fila do processo se `handle_info` demorar mais que 2s.
É o equivalente a usar `setTimeout` recursivo em vez de
`setInterval` no JavaScript — padrão mais seguro para
processos com trabalho variável.

### O estado do GenServer é a única fonte de verdade

```elixir
def init(_) do
  schedule_tick()
  {:ok, Machine.initial_machines()}  # estado inicial = lista de structs
end
```

A lista de máquinas vive **dentro do processo GenServer**.
Nenhuma variável global, nenhum banco neste fluxo.
Qualquer LiveView que queira os dados chama:

```elixir
Simulator.list_machines()
# → GenServer.call(__MODULE__, :list_machines)
# → devolve o estado atual sincronamente
```

---

## DashboardLive — O assinante reativo

### Subscrição condicional ao PubSub

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(WCore.PubSub, "machines:updates")
  end
  ...
end
```

Comparação com React:

```typescript
// React — equivalente com useEffect
useEffect(() => {
  const sub = pubsub.subscribe("machines:updates", handler);
  return () => sub.unsubscribe(); // cleanup
}, []); // só roda uma vez, após mount
```
