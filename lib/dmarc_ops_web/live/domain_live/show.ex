defmodule DmarcOpsWeb.DomainLive.Show do
  use DmarcOpsWeb, :live_view

  alias DmarcOps.Inventory
  alias DmarcOps.DNS.Wizard

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <!-- Header -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link navigate={~p"/domains"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="size-5" />
            </.link>
            <div>
              <h1 class="text-2xl font-bold"><%= @domain.name %></h1>
              <div class="flex items-center gap-2 mt-1">
                <.status_badge status={@domain.status} />
                <.policy_badge policy={@domain.current_policy} />
              </div>
            </div>
          </div>
          <div class="flex gap-2">
            <button phx-click="verify" class="btn btn-outline btn-sm">
              <.icon name="hero-arrow-path" class="size-4" />
              Verify DNS
            </button>
            <button phx-click="delete" data-confirm="Are you sure you want to delete this domain?" class="btn btn-error btn-outline btn-sm">
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
        </div>

        <!-- Authentication Status -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.auth_card title="SPF" status={@domain.spf_status} icon="hero-envelope" />
          <.auth_card title="DKIM" status={@domain.dkim_status} icon="hero-key" />
          <.auth_card title="DMARC" status={@domain.dmarc_status} icon="hero-shield-check" />
        </div>

        <!-- DNS Wizard -->
        <div class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-command-line" class="size-6" />
              DNS Records
            </h2>
            <p class="text-base-content/70 mb-4">
              Copy these DNS records to your domain registrar
            </p>

            <div class="space-y-4">
              <!-- Verification Record -->
              <.dns_record_card
                title="Verification TXT Record"
                description="Add this record first to verify domain ownership"
                record={@verification_record}
              />

              <!-- SPF Record -->
              <.dns_record_card
                title="SPF Record"
                description="Specifies which mail servers can send email for your domain"
                record={@spf_record}
              />

              <!-- DMARC Record -->
              <.dns_record_card
                title="DMARC Record"
                description="Sets your email authentication policy"
                record={@dmarc_record}
              />

              <!-- MTA-STS Record -->
              <.dns_record_card
                title="MTA-STS TXT Record"
                description="Enables strict transport security for email"
                record={@mta_sts_record}
              />

              <!-- TLS-RPT Record -->
              <.dns_record_card
                title="TLS-RPT Record"
                description="Receives TLS connection failure reports"
                record={@tls_rpt_record}
              />
            </div>
          </div>
        </div>

        <!-- MTA-STS Policy -->
        <div class="card bg-base-200">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-lock-closed" class="size-6" />
              MTA-STS Policy
            </h2>
            <div class="flex items-center gap-4 mb-4">
              <span class="text-base-content/70">Current Mode:</span>
              <.policy_mode_badge mode={@domain.mta_sts_mode} />
            </div>
            <div class="mockup-code bg-base-300">
              <pre><code><%= @mta_sts_policy %></code></pre>
            </div>
            <p class="text-sm text-base-content/60 mt-2">
              Host this at: <code class="text-primary">https://mta-sts.<%= @domain.name %>/.well-known/mta-sts.txt</code>
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Components

  defp status_badge(assigns) do
    color = case assigns.status do
      :pending -> "badge-warning"
      :verified -> "badge-success"
      :monitoring -> "badge-info"
      :enforced -> "badge-accent"
      _ -> "badge-ghost"
    end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"badge #{@color}"}><%= @status %></span>
    """
  end

  defp policy_badge(assigns) do
    color = case assigns.policy do
      :none -> "badge-ghost"
      :quarantine -> "badge-warning"
      :reject -> "badge-success"
      _ -> "badge-ghost"
    end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"badge #{@color}"}>p=<%= @policy %></span>
    """
  end

  defp policy_mode_badge(assigns) do
    color = case assigns.mode do
      :none -> "badge-ghost"
      :testing -> "badge-warning"
      :enforce -> "badge-success"
      _ -> "badge-ghost"
    end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"badge #{@color}"}><%= @mode %></span>
    """
  end

  defp auth_card(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <.icon name={@icon} class="size-6" />
            <h3 class="font-medium"><%= @title %></h3>
          </div>
          <%= if @status do %>
            <.icon name="hero-check-circle" class="size-6 text-success" />
          <% else %>
            <.icon name="hero-x-circle" class="size-6 text-error/50" />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp dns_record_card(assigns) do
    ~H"""
    <div class="bg-base-300 rounded-lg p-4">
      <div class="flex items-start justify-between mb-2">
        <div>
          <h4 class="font-medium"><%= @title %></h4>
          <p class="text-sm text-base-content/60"><%= @description %></p>
        </div>
        <button
          phx-click={JS.dispatch("phx:copy", to: "#record-#{hash_record(@record)}")}
          class="btn btn-ghost btn-sm"
        >
          <.icon name="hero-clipboard-document" class="size-4" />
          Copy
        </button>
      </div>
      <div class="grid grid-cols-3 gap-2 text-sm">
        <div>
          <div class="text-base-content/50">Name</div>
          <code id={"record-name-#{hash_record(@record)}"} class="text-primary"><%= @record.name %></code>
        </div>
        <div>
          <div class="text-base-content/50">Type</div>
          <code class="text-accent"><%= @record.type %></code>
        </div>
        <div class="col-span-3 mt-2">
          <div class="text-base-content/50">Value</div>
          <code id={"record-#{hash_record(@record)}"} class="text-xs break-all block bg-base-100 p-2 rounded mt-1"><%= @record.value %></code>
        </div>
      </div>
    </div>
    """
  end

  defp hash_record(record), do: :erlang.phash2(record)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user

    case Inventory.get_domain(user.agency_id, id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Domain not found")
         |> push_navigate(to: ~p"/domains")}

      domain ->
        {:ok, assign_domain_data(socket, domain)}
    end
  end

  defp assign_domain_data(socket, domain) do
    # Generate DNS records using the Wizard
    verification_record = Wizard.generate_verification(domain.name, code: domain.dns_verification_code)
    spf_record = Wizard.generate_spf(includes: ["_spf.google.com"])
    dmarc_record = Wizard.generate_dmarc(domain.name, policy: :none, rua: "dmarc@#{domain.name}")
    mta_sts_record = Wizard.generate_mta_sts_txt(domain.name)
    tls_rpt_record = Wizard.generate_tls_rpt(domain.name, rua: "tls-rpt@#{domain.name}")
    mta_sts_policy = Wizard.generate_mta_sts_policy(domain.name, mode: domain.mta_sts_mode)

    socket
    |> assign(:domain, domain)
    |> assign(:page_title, domain.name)
    |> assign(:verification_record, verification_record)
    |> assign(:spf_record, spf_record)
    |> assign(:dmarc_record, dmarc_record)
    |> assign(:mta_sts_record, mta_sts_record)
    |> assign(:tls_rpt_record, tls_rpt_record)
    |> assign(:mta_sts_policy, mta_sts_policy)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("verify", _params, socket) do
    # TODO: Implement DNS verification with :inet_res
    {:noreply, put_flash(socket, :info, "DNS verification coming soon!")}
  end

  def handle_event("delete", _params, socket) do
    case Inventory.delete_domain(socket.assigns.domain) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Domain deleted successfully")
         |> push_navigate(to: ~p"/domains")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete domain")}
    end
  end
end
