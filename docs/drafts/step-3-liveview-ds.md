# Step 3 — A Sala de Controle: Design System e LiveView

## O que foi implementado

- Design System próprio em `design_system.ex` com componentes
  HEEx reutilizáveis: `badge`, `card`, `stat`, `machine_card`, `alert`
- CSS customizado com tokens de design (variáveis CSS) em `app.css`
- Dashboard reativo em `DashboardLive` com resumo de status,
  grid de máquinas e highlight visual de mudanças em tempo real
- Animações via CSS puro — sem JavaScript customizado

---

## Arquitetura dos componentes

A decisão central foi criar um módulo separado `DesignSystem`
em vez de colocar os componentes dentro do próprio LiveView.

```
WCoreWeb.DesignSystem        # componentes puros — só recebem dados
      badge/1
      card/1
      stat/1
      machine_card/1
      alert/1

WCoreWeb.DashboardLive       # orquestra estado e eventos
      mount/3                # inicializa assigns
      handle_info/2          # reage ao PubSub
      render/1               # monta o template
      summary_card/1         # componente local (só usado aqui)
```

Essa separação segue o mesmo princípio do React de dividir
componentes "burros" (só renderizam dados) de componentes
"inteligentes" (gerenciam estado):

| React                            | LiveView                                    |
| -------------------------------- | ------------------------------------------- |
| Componente puro / presentational | `DesignSystem` — só recebe `assigns`        |
| Container component              | `DashboardLive` — gerencia estado e eventos |
| `props`                          | `attr` declarado no componente              |
| `children` / `{children}`        | `slot :inner_block`                         |

---

## Design System — decisões de implementação

### Tokens de design via variáveis CSS

Em vez de hardcodar cores em cada componente, centralizei
tudo em variáveis no `:root`:

```css
:root {
  --color-running: #22c55e;
  --color-idle: #94a3b8;
  --color-error: #ef4444;
  --color-maintenance: #f59e0b;
  --color-surface: #1e293b;
  --color-border: #334155;
}
```

Isso é o equivalente a um `theme.ts` no React com design tokens.
Se eu precisar mudar a cor de erro em todo o sistema, mudo
em um lugar só.

### Badge — pattern matching como lógica de apresentação

```elixir
defp badge_class(:running),     do: "wc-badge-running"
defp badge_class(:idle),        do: "wc-badge-idle"
defp badge_class(:error),       do: "wc-badge-error"
defp badge_class(:maintenance), do: "wc-badge-maintenance"
```

Aprendi que em Elixir não se usa `if/else` ou `switch` para
isso — usa-se **pattern matching em múltiplas cláusulas de
função**. O runtime escolhe qual executar pelo valor do argumento.

Comparação com React/TS:

```typescript
// React — switch ou objeto de lookup
const badgeClass = {
  running: "wc-badge-running",
  idle: "wc-badge-idle",
  error: "wc-badge-error",
  maintenance: "wc-badge-maintenance",
}[status];
```

Ambos resolvem o mesmo problema. O pattern matching do Elixir
tem uma vantagem: se eu passar um status inválido, o processo
crasha com erro claro em vez de retornar `undefined` silenciosamente.

### Card com slot

```elixir
slot :inner_block, required: true

def card(assigns) do
  ~H"""
  <div class={["wc-card", @class]}>
    <%= render_slot(@inner_block) %>
  </div>
  """
end
```

O `slot :inner_block` é equivalente ao `children` do React.
Permite compor o conteúdo do card de fora:

```heex
<%!-- HEEx --%>
<.card class="wc-machine-card">
  <h3>Conteúdo aqui</h3>
</.card>

<%!-- JSX equivalente --%>
<Card className="wc-machine-card">
  <h3>Conteúdo aqui</h3>
</Card>
```

---

## DashboardLive — o fluxo reativo

### Por que `build_summary` é uma função pura

```elixir
defp build_summary(machines) do
  Enum.reduce(machines, %{running: 0, idle: 0, error: 0, maintenance: 0}, fn machine, acc ->
    Map.update!(acc, machine.status, &(&1 + 1))
  end)
end
```

Em vez de guardar contadores separados no estado e atualizá-los
manualmente, o summary é **derivado da lista de máquinas** a
cada atualização. Isso evita inconsistência — não existe risco
de o contador ficar fora de sincronia com os dados reais.

É o mesmo princípio do `useMemo` no React: dados derivados não
devem viver no estado, devem ser calculados.

```typescript
// React — equivalente com useMemo
const summary = useMemo(
  () =>
    machines.reduce(
      (acc, m) => ({
        ...acc,
        [m.status]: (acc[m.status] ?? 0) + 1,
      }),
      { running: 0, idle: 0, error: 0, maintenance: 0 },
    ),
  [machines],
);
```

### O highlight — timer no servidor

Quando o PubSub entrega máquinas atualizadas, o LiveView
encontra qual mudou e sinaliza via `highlighted_id`:

```elixir
def handle_info({:machines_updated, machines}, socket) do
  highlighted_id = find_changed_machine(socket.assigns.machines, machines)

  if highlighted_id do
    Process.send_after(self(), :clear_highlight, 1_500)
  end

  {:noreply, assign(socket, machines: machines, highlighted_id: highlighted_id)}
end
```

O timer que remove o highlight (`Process.send_after`) roda
**no processo do servidor**, não no browser. O LiveView envia
apenas o diff do HTML atualizado via WebSocket.

No React, esse timer rodaria no browser com `setTimeout`.
O resultado visual é idêntico — a diferença é onde o código executa.

### Renderização condicional

```heex
<%= if @summary.error > 0 do %>
  <.alert type={:error} message={"#{@summary.error} máquina(s) com erro"} />
<% end %>
```

Idêntico ao React:

```tsx
{
  summary.error > 0 && (
    <Alert type="error" message={`${summary.error} máquina(s) com erro`} />
  );
}
```

---

## Por que CSS puro e não uma biblioteca

O desafio pede componentes HEEx criados sem bibliotecas
pesadas de UI. A decisão de usar CSS puro com tokens foi
intencional por três razões:

- Demonstra que entendo como estilização funciona por baixo
- Bundle menor — sem overhead de runtime de uma lib
- Controle total sobre cada detalhe visual

O Tailwind foi mantido como utilitário de base (reset, grid),
mas todos os componentes do Design System usam classes CSS
customizadas com prefixo `wc-` para evitar colisões.

---
