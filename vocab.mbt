///|
pub fn vocab_values(name : String) -> Array[String] {
  match name {
    "attack-resource-level-ov" =>
      ["individual", "club", "contest", "team", "organization", "government"]
    "attack-motivation-ov" =>
      [
        "accidental", "coercion", "dominance", "ideology", "notoriety", "organizational-gain",
        "personal-gain", "personal-satisfaction", "revenge", "unpredictable",
      ]
    "hash-algorithm-ov" =>
      [
        "MD5", "SHA-1", "SHA-256", "SHA-512", "SHA3-256", "SHA3-512", "SSDEEP", "TLSH",
      ]
    "identity-class-ov" =>
      ["individual", "group", "system", "organization", "class", "unknown"]
    "implementation-language-ov" =>
      [
        "applescript", "bash", "c", "c++", "c#", "go", "java", "javascript", "lua",
        "objective-c", "perl", "php", "powershell", "python", "ruby", "rust", "scala",
        "swift", "typescript", "visual-basic", "x86-32", "x86-64",
      ]
    "indicator-type-ov" =>
      [
        "anomalous-activity", "anonymization", "benign", "compromised", "malicious-activity",
        "attribution", "unknown",
      ]
    "industry-sector-ov" =>
      [
        "agriculture", "aerospace", "automotive", "chemical", "commercial", "communications",
        "construction", "defense", "education", "energy", "entertainment", "financial-services",
        "government", "healthcare", "hospitality-leisure", "infrastructure", "insurance",
        "manufacturing", "mining", "non-profit", "pharmaceuticals", "retail", "technology",
        "telecommunications", "transportation", "utilities",
      ]
    "infrastructure-type-ov" =>
      [
        "amplification", "anonymization", "botnet", "command-and-control", "control-system",
        "exfiltration", "firewall", "hosting-malware", "hosting-target-lists", "phishing",
        "reconnaissance", "staging", "workstation", "unknown",
      ]
    "malware-type-ov" =>
      [
        "adware", "backdoor", "bot", "bootkit", "ddos", "downloader", "dropper",
        "exploit-kit", "keylogger", "ransomware", "remote-access-trojan", "resource-exploitation",
        "rogue-security-software", "rootkit", "screen-capture", "spyware", "trojan",
        "unknown", "virus", "webshell", "wiper", "worm",
      ]
    "malware-capabilities-ov" =>
      [
        "accesses-remote-machines", "anti-debugging", "anti-disassembly", "anti-emulation",
        "anti-memory-forensics", "anti-sandbox", "anti-vm", "captures-input-peripherals",
        "captures-output-peripherals", "captures-system-state-data", "cleans-traces-of-infection",
        "commits-fraud", "communicates-with-c2", "compromises-data-availability",
        "compromises-data-integrity", "compromises-system-availability", "controls-local-machine",
        "degrades-security-software", "degrades-system-updates", "determines-c2-server",
        "emails-spam", "evades-av", "exfiltrates-data", "fingerprints-host", "hides-artifacts",
        "hides-executing-code", "infects-files", "infects-remote-machines", "installs-other-components",
        "persists-after-system-reboot", "prevents-artifact-access", "prevents-artifact-deletion",
        "probes-network-environment", "self-modifies", "steals-authentication-credentials",
        "violates-system-operational-integrity",
      ]
    "malware-result-ov" => ["malicious", "suspicious", "benign", "unknown"]
    "pattern-type-ov" => ["stix", "pcre", "sigma", "snort", "suricata", "yara"]
    "processor-architecture-ov" =>
      ["alpha", "arm", "ia-64", "mips", "powerpc", "sparc", "x86", "x86-64"]
    "region-ov" =>
      [
        "africa", "eastern-africa", "middle-africa", "northern-africa", "southern-africa",
        "western-africa", "americas", "caribbean", "central-america", "latin-america-caribbean",
        "northern-america", "south-america", "asia", "central-asia", "eastern-asia",
        "southern-asia", "south-eastern-asia", "western-asia", "europe", "eastern-europe",
        "northern-europe", "southern-europe", "western-europe", "oceania", "antarctica",
        "australia-new-zealand", "melanesia", "micronesia", "polynesia",
      ]
    "report-type-ov" =>
      [
        "attack-pattern", "campaign", "identity", "indicator", "intrusion-set", "malware",
        "observed-data", "threat-actor", "threat-report", "tool", "vulnerability",
      ]
    "threat-actor-type-ov" =>
      [
        "activist", "competitor", "crime-syndicate", "criminal", "hacker", "insider-accidental",
        "insider-disgruntled", "nation-state", "sensationalist", "spy", "terrorist",
        "unknown",
      ]
    "threat-actor-role-ov" =>
      [
        "agent", "director", "independent", "infrastructure-architect", "infrastructure-operator",
        "malware-author", "sponsor",
      ]
    "threat-actor-sophistication-ov" =>
      [
        "none", "minimal", "intermediate", "advanced", "expert", "innovator", "strategic",
      ]
    "tool-type-ov" =>
      [
        "denial-of-service", "exploitation", "information-gathering", "network-capture",
        "credential-exploitation", "remote-access", "vulnerability-scanning", "unknown",
      ]
    "grouping-context-ov" =>
      ["suspicious-activity", "malware-analysis", "unspecified"]
    "opinion-ov" =>
      ["strongly-disagree", "disagree", "neutral", "agree", "strongly-agree"]
    "account-type-ov" =>
      [
        "unix", "windows-local", "windows-domain", "ldap", "tacacs", "radius", "nis",
        "openid", "facebook", "twitter",
      ]
    "windows-integrity-level-ov" => ["low", "medium", "high", "system"]
    "windows-service-start-type-ov" =>
      [
        "service-auto-start", "service-boot-start", "service-demand-start", "service-disabled",
        "service-system-start",
      ]
    "windows-service-type-ov" =>
      [
        "service-kernel-driver", "service-file-system-driver", "service-win32-own-process",
        "service-win32-share-process",
      ]
    "windows-service-status-ov" =>
      [
        "service-continue-pending", "service-pause-pending", "service-paused", "service-running",
        "service-start-pending", "service-stop-pending", "service-stopped",
      ]
    "encryption-algorithm-ov" =>
      ["AES-256-GCM", "ChaCha20-Poly1305", "mime-type-indicated"]
    _ => []
  }
}

///|
pub fn vocab_contains(name : String, value : String) -> Bool {
  vocab_values(name).contains(value)
}

///|
pub fn is_open_vocab_value(value : String) -> Bool {
  value.length() > 0
}
