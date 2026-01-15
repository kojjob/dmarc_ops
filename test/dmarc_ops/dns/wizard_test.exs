defmodule DmarcOps.DNS.WizardTest do
  use ExUnit.Case, async: true

  alias DmarcOps.DNS.Wizard

  describe "generate_spf/1" do
    test "generates basic SPF record with Google" do
      record = Wizard.generate_spf(includes: ["_spf.google.com"])
      assert record.name == "@"
      assert record.type == "TXT"
      assert record.value == "v=spf1 include:_spf.google.com ~all"
    end

    test "generates SPF record with multiple includes" do
      record = Wizard.generate_spf(includes: ["_spf.google.com", "spf.protection.outlook.com"])
      assert record.value == "v=spf1 include:_spf.google.com include:spf.protection.outlook.com ~all"
    end

    test "generates SPF with strict all" do
      record = Wizard.generate_spf(includes: ["_spf.google.com"], policy: :fail)
      assert record.value == "v=spf1 include:_spf.google.com -all"
    end

    test "generates SPF with neutral all" do
      record = Wizard.generate_spf(includes: ["_spf.google.com"], policy: :neutral)
      assert record.value == "v=spf1 include:_spf.google.com ?all"
    end
  end

  describe "generate_dkim/2" do
    test "generates DKIM CNAME for Google Workspace" do
      record = Wizard.generate_dkim("example.com", selector: "google")
      assert record.name == "google._domainkey"
      assert record.type == "TXT"
      assert String.starts_with?(record.value, "v=DKIM1;")
    end

    test "generates DKIM for custom selector" do
      record = Wizard.generate_dkim("example.com", selector: "s1", key: "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC...")
      assert record.name == "s1._domainkey"
      assert record.value =~ "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
    end
  end

  describe "generate_dmarc/2" do
    test "generates basic DMARC record with none policy" do
      record = Wizard.generate_dmarc("example.com", policy: :none, rua: "dmarc@example.com")
      assert record.name == "_dmarc"
      assert record.type == "TXT"
      assert record.value == "v=DMARC1; p=none; rua=mailto:dmarc@example.com"
    end

    test "generates DMARC with quarantine policy" do
      record = Wizard.generate_dmarc("example.com", policy: :quarantine, rua: "dmarc@example.com")
      assert record.value == "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
    end

    test "generates DMARC with reject policy and ruf" do
      record = Wizard.generate_dmarc("example.com",
        policy: :reject,
        rua: "dmarc@example.com",
        ruf: "forensic@example.com"
      )
      assert record.value == "v=DMARC1; p=reject; rua=mailto:dmarc@example.com; ruf=mailto:forensic@example.com"
    end

    test "generates DMARC with subdomain policy" do
      record = Wizard.generate_dmarc("example.com",
        policy: :reject,
        sp: :quarantine,
        rua: "dmarc@example.com"
      )
      assert record.value =~ "sp=quarantine"
    end

    test "generates DMARC with percentage" do
      record = Wizard.generate_dmarc("example.com",
        policy: :quarantine,
        pct: 50,
        rua: "dmarc@example.com"
      )
      assert record.value =~ "pct=50"
    end
  end

  describe "generate_mta_sts/1" do
    test "generates MTA-STS TXT record" do
      record = Wizard.generate_mta_sts_txt("example.com")
      assert record.name == "_mta-sts"
      assert record.type == "TXT"
      assert record.value =~ "v=STSv1;"
      assert record.value =~ "id="
    end

    test "generates MTA-STS policy file content" do
      policy = Wizard.generate_mta_sts_policy("example.com", mode: :testing)
      assert policy =~ "version: STSv1"
      assert policy =~ "mode: testing"
      assert policy =~ "mx: *.example.com"
    end

    test "generates MTA-STS policy with enforce mode" do
      policy = Wizard.generate_mta_sts_policy("example.com", mode: :enforce, max_age: 604800)
      assert policy =~ "mode: enforce"
      assert policy =~ "max_age: 604800"
    end
  end

  describe "generate_tls_rpt/1" do
    test "generates TLS-RPT TXT record" do
      record = Wizard.generate_tls_rpt("example.com", rua: "tls-rpt@example.com")
      assert record.name == "_smtp._tls"
      assert record.type == "TXT"
      assert record.value == "v=TLSRPTv1; rua=mailto:tls-rpt@example.com"
    end
  end

  describe "generate_verification/1" do
    test "generates verification TXT record" do
      record = Wizard.generate_verification("example.com", code: "dmarc-ops-verify=abc123")
      assert record.name == "@"
      assert record.type == "TXT"
      assert record.value == "dmarc-ops-verify=abc123"
    end
  end
end
