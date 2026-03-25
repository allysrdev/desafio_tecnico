

defmodule WCoreWeb.DesignSystem do
@moduledoc """
Módulo que contém os componentes reutilizáveis do Design System W-Core.
Define elementos básicos como badges, cards, estatísticas e alertas,
promovendo consistência visual e funcionalidade.
"""
  use Phoenix.Component

  @doc """
  Renderiza um badge de status.

  ## Atributos
  * `:status` (átomo, obrigatório): O status da máquina (:running, :idle, :error, :maintenance).

  ## Exemplos
      <.badge status={:running} />
  """

  attr :status, :atom, required: true,
    values: [:running, :idle, :error, :maintenance],
    doc: "O status da máquina que define cores e rótulos"

  def badge(assigns) do
    ~H"""
    <span class={["wc-badge", badge_class(@status)]} role="status" aria-label={"Status: #{badge_label(@status)}"} >
      <span class="wc-badge-dot" aria-hidden="true"></span>
      <%= badge_label(@status) %>
    </span>
    """
  end

  defp badge_class(:running),     do: "wc-badge-running"
  defp badge_class(:idle),        do: "wc-badge-idle"
  defp badge_class(:error),       do: "wc-badge-error"
  defp badge_class(:maintenance), do: "wc-badge-maintenance"

  defp badge_label(:running),     do: "Operando"
  defp badge_label(:idle),        do: "Ocioso"
  defp badge_label(:error),       do: "Erro"
  defp badge_label(:maintenance), do: "Manutenção"

  attr :class, :list, default: [], doc: "Classes CSS adicionais"
  slot :inner_block, required: true

   @doc """
    Card base para agrupamento de layout
  """
  def card(assigns) do
    ~H"""
    <div class={["wc-card", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end


  @doc """
  Renderiza unidade estatística única (label e value)
  """
  attr :label, :string, required: true, doc: "A descrição da métrica"
  attr :value, :string, required: true, doc: "O valor formatado para exibição"

  def stat(assigns) do
    ~H"""
    <div class="wc-stat-item">
      <span class="wc-stat-label"><%= @label %></span>
      <span class="wc-stat-value"><%= @value %></span>
    </div>
    """
  end

   @doc """
  Componente primário para disponibilização de informações da máquina no grid.
  Inclui header com ID/Name, badge de status e métricas técnicas
  """

  attr :machine,     :map,     required: true, doc: "Os dados da máquina (struct ou map)"
attr :highlighted, :boolean, default: false, doc: "Se deve aplicar um destaque visual na atualização"

def machine_card(assigns) do
  ~H"""
  <.card class={[
    "wc-machine-card",
    machine_card_class(@machine.status),
    @highlighted && "wc-machine-card-highlight"
  ]}>
    <div class="wc-machine-card-header">
      <header>
        <p class="wc-machine-card-id"><%= @machine.id %></p>
        <h3 class="wc-machine-card-name"><%= @machine.name %></h3>
      </header>
      <.badge status={@machine.status} />
    </div>
    <div class="wc-machine-card-stats" role="group" aria-label="Métricas técnicas da máquina">
      <.stat label="Temperatura" value={"#{@machine.temperature}°C"} />
      <.stat label="Uptime"      value={format_uptime(@machine.uptime)} />
      <.stat label="Atualizado"  value={format_time(@machine.last_updated)} />
    </div>
  </.card>
  """
end

  defp machine_card_class(:error), do: "wc-machine-card-error"
  defp machine_card_class(_),      do: ""

  @doc """
  Renderiza alertas contextuais para notificações do sistema.
  Inclui suporte a aria-live para anunciar mudanças críticas.
  """
  attr :type, :atom, default: :info, values: [:info, :warning, :error, :success]
  attr :message, :string, required: true
  attr :class, :string, default: nil


  def alert(assigns) do
    ~H"""
    <div class={["wc-alert", alert_class(@type)]} role="alert" aria-live={if @type == :error, do: "assertive", else: "polite"}>
      <span><%= alert_icon(@type) %></span>
      <span><%= @message %></span>
    </div>
    """
  end

  defp alert_class(:info),    do: "wc-alert-info"
  defp alert_class(:warning), do: "wc-alert-warning"
  defp alert_class(:error),   do: "wc-alert-error"
  defp alert_class(:success), do: "wc-alert-success"

  defp alert_icon(:info),    do: "ℹ"
  defp alert_icon(:warning), do: "⚠"
  defp alert_icon(:error),   do: "✕"
  defp alert_icon(:success), do: "✓"

  defp format_uptime(0),    do: "Offline"
  defp format_uptime(secs) do
    h = div(secs, 3600)
    m = div(rem(secs, 3600), 60)
    "#{h}h #{m}m"
  end

  defp format_time(dt) do
    dt
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%H:%M:%S")
  end
end
