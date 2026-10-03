# Network diagnostic journal

Times: Europe/Helsinki. Rates: Mbps down/up unless stated otherwise.
Keep entries to conditions, findings and next steps; raw data stays outside Git.

## Baseline

Pannu (wired) → stationary RB5009 → Sagemcom FAST3896. WAN ether8: 1 Gbps;
LAN uplink: 10 Gbps; ether1 transit to kuberack: 2.5 Gbps. CAKE baseline: outer
800/80, internal bandwidth zero. LAN-to-LAN qualifies for FastTrack; WAN does not.

## September 10 — coax replacement

Cable and splitter replaced ~22:29–22:33 without reboot. By September 12 morning,
uncorrectables remained at 69,761,355; none added over 24 hours. SNR: 41–43 dB.

## September 11–12 — public sweep

Hostkey/Worldstream; 36 settings × five rounds. Each trial: 15s idle, 5s warm-up,
60s simultaneous load, eight download/four upload streams. Separate capacity
checks bypassed CAKE; each trial restored 800/80 afterward.

Completed 180/180 at September 12 10:16:52: 129 near both caps, 50 underloaded,
one unassessed. Underloaded results cannot establish successful queue control.
At the 164-trial checkpoint, five 600/50 runs had Google p95 10.3–15.3 ms,
peak 32.3 ms and zero lost probes. Five 800/60 runs: p95 12.5–19.1 ms,
peak 33.9 ms, two lost probes. Final ranking pending.

Data on pannu: `~/.local/state/cake-sweep/`.

## September 12 — private sweep and bottleneck checks

Poenttoe; five rounds of 600/50, 700/70, 800/60, 800/80,
900/90, same load method; 250 GB estimate budget. Started 10:33:13, no overlap
with public sweep. Currently paused for router testing.

- Separate capacity: 490/82. First simultaneous trials: 489/21 and 484/15;
  Google p95 259/293 ms, one lost probe per 335; router p95 ~1 ms.
- Pannu → public servers, separate directions, CAKE bypassed: 414–417/84–86.
- Poenttoe → Hostkey, separate: 827 receive / 938 send; → Worldstream:
  receive busy, 3511 send. Poenttoe has no fixed ~490 Mbps sending ceiling.
- Other local traffic during one check: ~0.04/0.03 versus test ~504/43.
- Router later forwarded ~694/48; busiest sampled core 61%. No Ethernet errors.
  This excludes a fixed 490 Mbps ceiling, not transient router saturation.
- Modem-side cable change did not change router WAN: ether8 remains 1 Gbps.

Data: pannu `~/.local/state/cake-validation/` and
`~/.local/state/cake-public-recheck-1789198953/`; poenttoe
`~/.local/state/cake-endpoint-check-1789199134/`.

## Next — routed LAN test

Pannu ↔ w1 behind kuberack; separate and simultaneous load, both routers' per-core
CPU. Verify route, link speeds and FastTrack. This will not reproduce WAN CAKE.
Minimal Nix image built, smoke-tested and pushed to Harbor; ArgoCD manifests
passed admission dry runs. Awaiting merge/sync; no endpoint deployed or test run.

## September 12 — CAKE off, WAN FastTrack off

Three rounds against poenttoe: 15s idle, 5s warm-up, 30s load per mode;
mode order rotated. Google idle p95 19–21 ms.

| Mode | Actual Mbps ↓/↑ | Google p95 | Peak sampled core |
|---|---|---|---|
| Download only | 820–838 / — | 76–251 ms | 49–61% |
| Upload only | — / 95.8–96.0 | 24–27 ms | 29–31% |
| Simultaneous | 708–848 / 37–87 | 108–241 ms | 57–61% |

Loss across 1,665 probes per target: Google 0, router 0, Cloudflare 1.
Substantial download-loaded delay without observed core saturation; transient
CPU limits remain possible. CAKE left disabled, WAN FastTrack unchanged.
Data on pannu: `~/.local/state/cake-unshaped-1789202321/`.

### 2026-09-12 — Firewall adoption

Imported 92 static firewall entries across both routers; bootstrap and Terraform
now share their definitions and filter order. Live rules/order unchanged; CHR
adoption, order repair, and reset recovery passed. CAKE remains disabled.

### 2026-09-13 — Routed LAN throughput

Pannu ↔ w1 through both routers, physical 2.5G transit, LAN FastTrack; Stationary
CAKE disabled, WAN sweeps stopped. Pannu USB NIC: 2.5G Ethernet/5G USB; w1: 10G.
Three 20s runs/mode, four TCP streams/direction, 3s warmup; CPU sampled every ~2s.

| Mode (relative to pannu) | Received Gbps ↓/↑ |
|---|---|
| Download only | 2.290–2.297 / — |
| Upload only | — / 2.279–2.292 |
| Simultaneous | 1.413–2.158 / 2.079–2.270 |

Peak sampled core: Stationary 55%, Kuberack 45%. No new FCS errors; queue drops
and TCP retransmissions occurred. Kuberack RX overflows rose during simultaneous
runs (ether1 +1,048; SFP +3,171). High LAN throughput is established, but buffering
pressure remains; this FastTrack path does not validate WAN/CAKE processing.
Raw iperf results on pannu: `~/.local/state/router-throughput/1789299826/`;
router samples and copied results at the same path on this laptop.

### 2026-09-13 — Routed LAN without FastTrack

Repeated the same three runs/mode with both routers' FastTrack rules disabled
through a temporary Terraform override. Active test connections verified
`fasttrack=false` on both routers. CAKE unchanged; new TCP connections each run.

| Mode (relative to pannu) | Received Gbps ↓/↑ |
|---|---|
| Download only | 2.278–2.289 / — |
| Upload only | — / 2.281–2.290 |
| Simultaneous | 1.540–2.009 / 1.502–2.167 |

Both routers reached 100% on a sampled core during simultaneous traffic;
single-direction peaks were 82%/81% (Stationary/Kuberack). Queue pressure and
retransmissions persisted; Kuberack RX overflows increased, with no new FCS errors.
Single-direction throughput remained near the FastTrack baseline, with much less
CPU headroom. Restored LAN FastTrack through Terraform and removed the override.
Raw data: `~/.local/state/router-throughput/no-fasttrack-1789301204/` (iperf on
pannu; router samples and copied results on this laptop). Earlier aborted trial
`no-fasttrack-1789301040` is excluded: its connection-verification filter was wrong.

### 2026-09-13 — WAN FastTrack comparison, CAKE disabled

Pannu ↔ poenttoe over public IPv4. Temporary Terraform rule enabled WAN FastTrack
only for pannu TCP 5201–5202; active test connections verified. Three 30s runs/mode,
5s warmup, eight download/four upload streams; 15s idle per round. After removing
the rule, repeated one control run/mode and verified `fasttrack=false`.

| Mode | FastTrack Mbps ↓/↑ (3 runs) | Google p95 ms | Control Mbps ↓/↑ (1 run) | Google p95 ms |
|---|---|---|---|---|
| Download | 734–801 / — | 395–400 | 717 / — | 251 |
| Upload | — / 84–93 | 284–597 | — / 96 | 53 |
| Simultaneous | 746–797 / 21–38 | 365–674 | 642 / 26 | 248 |

Idle Google p95: 19–21ms with FastTrack, 24ms before control. Peak sampled core:
42% versus 70%; router p95 stayed below 0.5ms. No loss in 2,220 probes/target
(router, Google, Cloudflare) across loaded trials. Estimated transfer: 31.16GB
from iperf accounting, including its overhead allowance; not provider billing.

FastTrack did not eliminate loaded latency. The later control had lower latency,
but sequential, unequal sample sets cannot isolate causality. These runs neither
locate the WAN bottleneck nor validate DOCSIS health. Restored LAN-only FastTrack;
CAKE remains disabled; full Terraform plan reports no changes.
Raw data on pannu and laptop: `~/.local/state/cake-wan-fasttrack-1789313016/`
and `~/.local/state/cake-wan-control-1789313590/`. Initial attempt stopped before
traffic on an enabled-state assertion; retried with explicit `disabled=false`.

### 2026-09-13 — Alternating CAKE off versus 500/50

Pannu ↔ poenttoe, simultaneous TCP, three alternating off/on pairs; 30s measured,
5s warmup, eight download/four upload streams, 15s idle per trial. WAN FastTrack
verified absent. Temporary Terraform overrides changed only Stationary CAKE's
limits/enabled state; existing HTB shaping and CAKE options retained.

| Pair | Off Mbps ↓/↑ | Off Google p95 ms | 500/50 Mbps ↓/↑ | Shaped Google p95 ms |
|---|---|---|---|---|
| 1 | 638/20 | 327 | 487/43 | 16.6 |
| 2 | 779/83 | 425 | 479/40 | 143 |
| 3 | 761/47 | 853 | 488/43 | 11.6 |

Idle p95: 20–23ms. Shaping improved latency in every pair, but the 143ms trial
precludes a consistently low-latency claim. Peak sampled core: off 50%, on 60%.
One lost probe each to Google/Cloudflare in the last off trial; none in shaped
trials or to the router. This does not isolate ACK contention or the exact WAN
bottleneck. Restored CAKE disabled at 800/80; temporary files removed.
Raw data on pannu/laptop: `~/.local/state/cake-ab-1789314231/`; accounting estimates
26.79GB including one failed attempt. Excluded incomplete off trial: connection
API returned HTTP 404; identical read subsequently succeeded, final pair repeated.
Earlier setup attempt `cake-ab-1789314126` stopped after one off run because
Terraform rejected a new variable in an override file; no shaped apply occurred.

### 2026-09-13 — Start-order interaction

CAKE/WAN FastTrack off; no infrastructure changes. Four 85s transfers in order
upload/download/download/upload, adding the opposite direction at ~25s for 35s.
Same eight download/four upload TCP streams. Primary interval rates sampled at
10–23s / 35–55s / 70–83s (before / overlap / after):

| Primary | Before Mbps | Overlap Mbps | After Mbps |
|---|---|---|---|
| Upload 1 | 76 | 87 | 53 |
| Download 1 | 700 | 673 | 618 |
| Download 2 | 652 | 668 | 673 |
| Upload 2 | 84 | 74 | 93 |

Upload intervals are sender rates; download intervals are receiver rates.
Crucially, new uploads started during established downloads received only 21/12
Mbps over their 35s runs, versus established uploads sustaining 87/74 Mbps during
overlap. Start-order/TCP dynamics appear important; two repeats do not isolate
the mechanism. High RTT/retransmissions also occurred before overlap, so earlier
separate-run comparisons cannot attribute all variability to simultaneous load.
Router peak sampled core 55%; poenttoe CPU idle >=76% in collected vmstat samples.
Raw data: `~/.local/state/wan-interaction-1789316121/` on pannu/laptop; estimated
transfer 23.60GB. No packet capture or DOCSIS correlation performed in this test.

### 2026-09-13 — Start-order repeat with CAKE 500/50

Repeated the same four staged transfers with existing CAKE options and temporary
500/50 HTB limits via Terraform; WAN FastTrack remained absent. Established
uploads sustained 42.8/42.9 Mbps during overlap (sender intervals). New uploads
started during established downloads received 43.1/42.5 Mbps, versus 21.5/11.8
Mbps unshaped. Established downloads held 479–486 Mbps during overlap.

Google overlap p95: 14.3/20.4/20.0/18.2ms. First upload-only pre-overlap phase had
192ms p95; remaining non-overlap phases were 9–30ms. CAKE removed the pronounced
start-order penalty in these repeats, but consistently low latency is not yet
established. Peak sampled router core 62%; estimated transfer 17.39GB.
Restored disabled CAKE at 800/80 and removed temporary Terraform files.
Raw data on pannu/laptop: `~/.local/state/wan-interaction-cake-1789317034/`.

### 2026-09-13 — First rate increases, competing upload identified

Alternated three simultaneous runs each at 600/50 and 500/60, bracketed by
500/50 references; same 30s measurements, 5s warmup, 15s idle and TCP streams.

| Limit ↓/↑ | Received Mbps ↓/↑ | Google p95 ms |
|---|---|---|
| 500/50 references | 482–486 / 42.6–42.7 | 18–21 |
| 600/50 | 571–577 / 27–42 | 21–24 |
| 500/60 | 469–488 / 38–52 | 17–33 |

During the low-upload 600/50 trial, queue upload was ~49Mbps despite only 27Mbps
iperf payload. Subsequent connection-counter sampling found zima uploading
~22Mbps independently. Transmission runs there in a WireGuard namespace; a later
RPC sample showed negligible upload, so background activity was variable. These
are household-load results, not isolated capacity measurements. Peak sampled
core 76%. Restored CAKE disabled at 800/80; no temporary Terraform files retained.
User requested stopping Transmission for repeats; SSH service control required
interactive authentication, root SSH failed, and the service was not stopped.
Raw data: `~/.local/state/cake-increase-1789318372/` on pannu/laptop.

### 2026-09-13 — Rate increases with Transmission stopped

User stopped zima's Transmission; verified inactive before each trial. Repeated
three alternating 600/50 and 500/60 simultaneous runs between 500/50 references.

| Setting | Received Mbps ↓/↑, chronological | Google p95 ms |
|---|---|---|
| 500/50 before | 480/43 | 20 |
| 600/50 | 569/42; 585/40; 335/9 | 24; 46; 975 |
| 500/60 | 487/51; 481/51; 372/8 | 34; 30; 588 |
| 500/50 after | 361/9 | 684 |

Late deterioration also affected the original reference, so limit increases
alone do not explain it. Transmission was not responsible for this episode.
Router sampled CPU fell during poor runs; both external pings slowed while local
router latency stayed low. Latest DOCSight poll showed online, minimum valid SNR
41dB, and no downstream corrected/uncorrected counter increase over 15m; poll age
was ~102s, so this does not exclude transient or upstream/path problems.
No higher rate is validated as reliably low latency. Estimated transfer 18.79GB.
Restored CAKE disabled at 800/80 through Terraform. Automatic Transmission restart
failed because interactive authentication is required; user must restart it.
Raw data on pannu/laptop: `~/.local/state/cake-increase-quiet-1789319117/`.

### 2026-09-13 — Unshaped recheck after reported speed recovery

Pannu → poenttoe, CAKE/WAN FastTrack off, Transmission still stopped. One 30s run
per mode: download 333Mbps (Google p95 875ms), upload 65Mbps (458ms), simultaneous
498/24Mbps (529ms); idle p95 20ms. Router peak sampled core 45%. Thus poor loaded
latency persisted with shaping disabled; a separate public speed-test result
cannot establish recovery on this path. Estimated transfer 4.34GB. No settings
changed; Transmission restart remains pending user authentication.
Raw data: `~/.local/state/cake-wan-control-1789319886/` on pannu/laptop.

### 2026-09-13 — Continuous WAN and device accounting

CAKE/WAN FastTrack off; Transmission confirmed stopped. One 30s run per mode,
15s idle before each. Sampled WAN byte counters, connection byte counters and
CPU approximately every 2s; attributed LAN-originated traffic and identifiable
inbound replies to devices, separating pannu's iperf connections.

| Test | iperf Mbps ↓/↑ | Google p95 ms | Other attributed Mbps ↓/↑ |
|---|---|---|---|
| Download | 640 / — | 308 | 1.16 / 0.29 |
| Upload | — / 77 | 685 | 0.81 / 0.13 |
| Both | 691 / 66 | 533 | 0.25 / 0.09 |

Idle p95 ~20–22ms. No large competing transfer observed. Attribution is sampled,
not packet-exact: short-lived connections, non-atomic reads and different counter
layers leave residuals (both: ~14.5/1.8Mbps against WAN totals ~720/74Mbps).
High loaded latency without CAKE is compatible with bufferbloat, not proof of a
fault. These observations cannot establish absence of traffic in earlier runs.
Estimated test transfer 7.14GB; no configuration changes. Transmission restart
still requires user authentication. Raw data plus traffic-analysis.json:
`~/.local/state/wan-observed-1789320355/` on laptop (raw data also on pannu).

### 2026-09-13 — Monitored 500/50 baseline repeat

Repeated the previous three modes with CAKE enabled at 500/50 through Terraform;
same continuous WAN/device accounting, Transmission stopped, WAN FastTrack off.

| Test | Received Mbps ↓/↑ | Google p95 ms, off → on |
|---|---|---|
| Download | 449 / — | 308 → 46 |
| Upload | — / 48 | 685 → 12 |
| Both | 462 / 42 | 533 → 24 |

Idle p95 ~21ms. Recorded other traffic averaged 0.38–2.15Mbps down and
0.18–0.25Mbps up across trials; no large competing transfer observed. No loss
in 555 probes/target across loaded trials. Peak sampled core 66%; estimated
transfer 4.72GB. Single runs demonstrate improvement, not long-term reliability.
Restored CAKE disabled at 800/80. Transmission remains stopped pending user restart.
Raw data/analysis: `~/.local/state/wan-observed-cake-1789320681/` on laptop;
raw data also on pannu.

### 2026-09-13 — Upload-only limit map

Two passes, 50→65→80→90→90→80→65→50Mbps upload; download cap fixed at 500.
Same 30s load/5s warmup/15s idle, four upload streams, CAKE HTB shaping. Added
modem ping, per-sample TCP state, iperf server output, poenttoe CPU/Cloudflare
observations; retained WAN/device accounting. Transmission stayed stopped.

| Upload cap | Received Mbps (two runs) | Google p95 ms |
|---|---|---|
| 50 | 48.6 / 48.3 | 9.4 / 10.6 |
| 65 | 62.4 / 62.7 | 16.6 / 10.1 |
| 80 | 77.2 / 74.4 | 8.9 / 28.4 |
| 90 | 86.5 / 86.2 | 12.0 / 12.6 |

Modem p95 3.08–3.30ms; no Google ping loss or throughput collapse in valid runs.
Other attributed traffic per-run averages <=2.42Mbps down/0.28Mbps up. 90Mbps is
an upload-only candidate, not a validated simultaneous optimum. Next: locate
upper upload boundary, map download independently, then verify combined settings.
One 80Mbps attempt aborted on connection-print HTTP 404; restored and retried.
Added logged bounded retries for that read; persistent failures still abort.
Payload recorded 2.36GB; accounting 10.92GB includes an 8.32GB failed-attempt
reservation. Restored CAKE disabled at 800/80. Transmission restart remains pending.
Raw data: `~/.local/state/cake-upload-map-1789321386/` on pannu/laptop;
poenttoe observations under laptop `~/.local/state/firewall-adoption/poenttoe-upload-map.*`.

### 2026-09-13 — Upload ceiling and independent observations

Upload-only 90→95→100→100→95→90Mbps, otherwise same monitored setup.

| Cap | Received Mbps (two runs) | Google p95 ms |
|---|---|---|
| 90 | 78.2 / 79.3 | 67.5 / 115 |
| 95 | 86.8 / 91.8 | 252 / 13.7 |
| 100 | 93.2 / 95.7 | 35.4 / 21.3 |

No Google loss. Other attributed upload <=0.46Mbps; first two trials had ~9Mbps
background download, later trials <=1.12Mbps. Modem p95 remained 3.12–3.32ms.
During matching windows, poenttoe→Cloudflare p95 was 1.43–1.52ms; server CPU
idle >=80% across observed samples. Thus server-wide CPU/latency degradation was
not observed, and modem management remained responsive; this does not rule out
modem data-path queues or congestion between endpoints.

A lower cap did not consistently yield lower latency, weakening any claimed
fixed ceiling from these short runs. Next compare HTB versus CAKE-native shaping
at identical rates before expanding the download/combined matrix. No optimal
permanent setting selected. Estimated transfer 2.51GB. Restored CAKE disabled at
800/80; Transmission remains stopped for testing, restart still pending.
Raw data: `~/.local/state/cake-upload-ceiling-1789322231/` on pannu/laptop;
server observations: laptop `~/.local/state/firewall-adoption/poenttoe-upload-ceiling.*`.

### 2026-09-13 — HTB versus CAKE-native at 500/90

Alternated shaping methods, two upload-only and two simultaneous runs per method.
Native used simple max-limit 0/0 with rx/tx CAKE bandwidth 500M/90M; HTB used
500M/90M simple limits with native bandwidth zero. All other options unchanged;
active queue/type settings verified throughout. Same monitored test procedure.

| Method / load | Received Mbps ↓/↑ (two runs) | Google p95 ms |
|---|---|---|
| HTB upload | — / 86.7; — / 86.9 | 11.2 / 15.9 |
| Native upload | — / 85.6; — / 85.5 | 9.1 / 9.5 |
| HTB simultaneous | 388/58; 445/72 | 218 / 50.9 |
| Native simultaneous | 408/12; 379/10 | 640 / 492 |

Native shaping did not remove the collapse; both native simultaneous trials
were worse than their HTB counterparts. During the first native failure, other
traffic was only 0.16/0.07Mbps and sampled queue backlog was mostly zero. Modem
management and poenttoe's independent Cloudflare probes stayed responsive.
The exact bottleneck remains unproven; 500/90 is not a reliably low-latency pair.
Keep HTB for subsequent download-only and combined-rate mapping. Restored disabled
800/80 and zero native bandwidth explicitly before removing temporary Terraform
files; Transmission restart remains pending. Raw data/analysis on pannu/laptop:
`~/.local/state/cake-shapers-1789322936/`; server observations on laptop under
`~/.local/state/firewall-adoption/poenttoe-shapers.*`.

### 2026-09-13 — Download cap map

HTB download-only, two passes in opposite order; upload cap 50Mbps.

| Download cap Mbps | Received Mbps | Google p95 ms |
|---|---|---|
| 300 | 282–286 | 21–27 |
| 450 | 413–427 | 26–40 |
| 600 | 432–504 | 58–107 |
| 750 | 422–564 | 206–266 |
| 900 | 647–686 | 207–231 |

300 was most consistent; 450 traded modest extra latency for throughput. Neither
is validated under sustained simultaneous load. One Google probe lost at 600;
final 300 trial still had a 77ms maximum. Restored CAKE disabled; final plan
showed no changes. Transmission restart pending. Raw data on pannu/laptop:
`~/.local/state/cake-download-map-1789323716/`.

### 2026-09-13 — Repeat 500/50 baseline

CAKE/HTB 500/50, WAN FastTrack off, Transmission stopped; wired pannu→poenttoe.
One 30s measured run per mode, each preceded by 15s idle.

| Load | Received Mbps ↓/↑ | Idle / loaded Google p95 ms |
|---|---|---|
| Download | 457 / — | 21.8 / 37.7 |
| Upload | — / 48.4 | 18.3 / 10.4 |
| Both | 461 / 41.9 | 18.2 / 31.7 |

No Google ping loss (555 probes total); simultaneous maximum 80.1ms. No collapse
in this short repeat; sustained stability remains unproven. Attributed background
traffic <=1.92Mbps down/0.11Mbps up; WAN accounting residual reached 20.9/2.0Mbps,
so attribution is approximate. Peak sampled router core 60%. Restored CAKE disabled
at 800/80; Transmission restart still pending. Raw evidence on pannu/laptop:
`~/.local/state/cake-baseline-repeat-1789324883/`.

### 2026-09-13 — Combined lower-cap comparison

HTB, simultaneous load, two 30s trials per pair in opposite order; 15s idle each.
WAN FastTrack off; Transmission stopped.

| Cap ↓/↑ Mbps | Received ↓/↑ Mbps | Google p95 ms |
|---|---|---|
| 300/50 | 291–292 / 44.7 | 13.3–15.6 |
| 300/70 | 289–291 / 63.4–63.7 | 13.9–17.3 |
| 450/50 | 416–437 / 42.0–43.8 | 15.2–25.9 |
| 450/70 | 418–432 / 58.4–62.2 | 19.1–40.4 |

Idle p95 19.7–22.4ms; no Google loss across 1,480 probes and no collapse.
300/70 retained ~19Mbps more upload than 300/50 with similar p95; candidate for
low latency. 450/50 retained ~125–145Mbps more download, sacrificing ~20Mbps
upload. Neither is a sustained optimum yet; next repeat/extend these candidates.
Attributed background <=1.07/0.24Mbps; server CPU idle >=73%, matching-window
server→Cloudflare p95 1.51–2.14ms. Modem p95 3.32–7.14ms. Estimated transfer
15.46GB. Restored disabled 800/80; full Terraform plan showed no changes.
Transmission restart pending. Raw data: `~/.local/state/cake-combined-map-1789325169/`
on pannu/laptop; server observations under laptop
`~/.local/state/firewall-adoption/poenttoe-combined-map.*`.

### 2026-09-13 — Sustained candidate comparison

Two 120s simultaneous runs per pair, order 300/70→450/50→450/50→300/70.
Same HTB setup, WAN FastTrack off, Transmission stopped.

| Cap ↓/↑ Mbps | Received ↓/↑ Mbps | Google p95 / maximum ms |
|---|---|---|
| 300/70 | 289–291 / 62.8–63.6 | 14–20 / 26.7–53.6 |
| 450/50 | 417–422 / 42.1–42.5 | 25.3–29.2 / 45.2–59.6 |

Idle p95 19–21.5ms; no Google loss across 2,540 probes. Early (10–40s) versus
late (90–120s) throughput stayed within 1% down/2% up; no delayed collapse.
Lowest ten-second averages: ~276/60Mbps at 300/70; ~397/40Mbps at 450/50. First ten seconds
excluded from interval comparisons because iperf reported inconsistent duration
for the first non-omitted interval; full-run throughput uses received byte totals.

Background attribution <=1.26/0.13Mbps; poenttoe CPU idle >=73% and matching
Cloudflare p95 1.53–1.61ms. 300/70 remains the lower-latency candidate; 450/50
gains ~130Mbps down at ~21Mbps upload cost. Longer uptime stability and the
intermediate rate boundary remain unproven. Estimated transfer 27.90GB.
Restored disabled 800/80; final Terraform plan no changes. Transmission restart
pending. Raw data on pannu/laptop: `~/.local/state/cake-sustained-1789325874/`;
server observations: laptop `~/.local/state/firewall-adoption/poenttoe-sustained.*`.

### 2026-09-13 — Combined boundary and variable-capacity evidence

Short 375/70 trials delivered 348–362/60–63Mbps at 18.7–31ms Google p95;
300/70 control was 288/62.9 at 16.4ms and 450/50 was 422/42.4 at 24.8ms.
No measured-window loss. The final SSH channel broke after its result was saved;
manual Terraform restoration changed only CAKE from 375/70 enabled to 800/80
disabled, and the final full plan was empty.

Two-minute 350/70 and 375/70 repeats showed 333–338/58.8–61.7Mbps at 28–65ms
and 353–357/61.6–61.7Mbps at 23–24ms. One brief public-path loss event occurred
immediately after a measurement window. During the poor 350/70 run, upload fell
from 63 to 53Mbps late and upload queue backlog peaked at 306KB, versus 67–78KB
in the other runs. Background traffic was <=2.28/0.15Mbps. Modem channel counts,
power, SNR, online/poll state, and downstream error counters stayed stable;
poenttoe-to-Cloudflare p95 was ~1.5ms. This supports variable downstream-of-CAKE
upload capacity, without identifying whether the modem data path, CMTS, ISP, or
route is responsible.

At 300Mbps download, two-minute 50 and 60Mbps upload-cap repeats delivered
282–292/44.3–44.4Mbps at 16.7–20ms and 274–292/52.0–53.9Mbps at 16.3–47ms.
The poor final 300/60 run started with 38ms idle p95 and frame-work downloaded
18.1Mbps over one UDP/443 connection to a Google-operated cache. Total WAN held
309/60Mbps, explaining most of iperf's decline; loaded p95 added ~9ms. Its single
Google loss was not repeated by Cloudflare, router, or modem. Earlier clean
300/60 held 292/54Mbps at 16.3ms. 300/60 is the current latency-first candidate;
download limits at this upload cap remain to be mapped. Estimated transfers:
9.69GB middle, 27.75GB boundary sustained, 22.82GB upload-safe sustained.
All batches restored CAKE disabled at 800/80 with empty final plans. Transmission
restart remains pending. Raw roots: `cake-middle-map-1789326664`,
`cake-boundary-sustained-1789327207`, and `cake-upload-safe-sustained-1789328044`
under `~/.local/state/` on pannu/laptop.

### 2026-09-13 — Final rate selection

Mapped simultaneous load at 300–400Mbps down with a fixed 60Mbps upload cap,
two short passes. A steady frame-work QUIC download consumed 17–18Mbps during
all trials, so iperf download was lower than total WAN throughput.

| Cap ↓/↑ Mbps | Received ↓/↑ Mbps | Google p95 ms |
|---|---|---|
| 300/60 | 266–270 / 43.6–54.4 | 11.7 / 65.7 |
| 325/60 | 297–301 / 53.5–54.1 | 11.1 / 19.0 |
| 350/60 | 320–327 / 52.8–53.9 | 13.2 / 20.6 |
| 375/60 | 333–351 / 49.0–53.7 | 14.7 / 81.9 |
| 400/60 | 372–375 / 53.4–53.6 | 15.2 / 16.4 |

The reverse 375/60 and final 300/60 controls failed together as total WAN upload
fell from ~62Mbps earlier to ~61 and then 50Mbps. Public-target p95 rose to 82
and 66ms while router/modem p95 remained <=4.7ms and poenttoe-to-Cloudflare p95
was 1.5–1.7ms. Thus 60Mbps is not a safe static upload cap when cable-path
capacity varies. There was no ping loss in this map.

Sustained finalists at a 50Mbps upload cap:

| Cap ↓/↑ Mbps | Received ↓/↑ Mbps | Google p95 ms |
|---|---|---|
| 400/50 | 378–381 / 43.9–44.1 | 15.0–17.5 |
| 425/50 | 401–405 / 43.6–43.8 | 18.8–22.4 |

All four two-minute trials had zero loss and stable early/late throughput.
Background download was 4.7–13Mbps; server CPU idle >=78% and matching server
p95 was 1.52–1.62ms. A final five-minute 400/50 run delivered 376.4/44.1Mbps,
Google p95/p99/max 15.9/26.3/47.4ms, and zero loss over 1,535 probes. First versus
last minute was 375.7→376.8Mbps down and 44.0→44.4Mbps up; lowest ten-second
averages were 365/42.8Mbps. Another LAN device downloaded 12.4Mbps during it.

Recommended static latency-first setting: HTB-backed CAKE at 400/50Mbps. The
425/50 alternative gains ~24Mbps download with a modestly higher latency tail.
Observed random iperf drops had two causes: competing LAN downloads reduced the
test flow while total WAN stayed capped, and the available public/cable upload
path sometimes fell below 60–70Mbps, moving the bottleneck beyond CAKE. The data
does not isolate modem data path, CMTS, ISP congestion, or route beyond the home.
Router CPU, poenttoe, modem online/channel/power/SNR state, and downstream error
counters did not explain the events. A static shaper cannot guarantee zero ping
increase when base path latency or available cable capacity changes.

Estimated transfers: 17.73GB for the 60Mbps map, 29.77GB for finalist repeats,
and 17.59GB for final validation. Restored CAKE disabled at 800/80; every final
Terraform plan was empty. Transmission restart remains pending. Raw roots:
`cake-download-at60-map-1789328977`, `cake-finalists-sustained-1789329868`, and
`cake-final-validation-1789330642` under `~/.local/state/` on pannu/laptop.

### 2026-09-14 — Good-condition high-rate sweep

Fresh unshaped checks reached 896.7/95.5Mbps separately and 900.4/89.0Mbps
simultaneously; the latter raised Google p95 to ~154ms. The CAKE campaign then
ran 74 trials with 53.5 minutes of measured load: a bracket, three randomized
passes over 800/850/900Mbps down × 70/80/90Mbps up, directional isolation, and
three two-minute finalist repetitions.

| Cap ↓/↑ Mbps | Average received ↓/↑ Mbps | Google p95 median / maximum ms |
|---|---|---|
| 800/70 | 772.7 / 61.8 | 13.9 / 28.7 |
| 800/80 | 784.7 / 71.5 | 14.1 / 17.9 |
| 800/90 | 781.9 / 80.8 | 15.0 / 30.5 |
| 850/70 | 835.1 / 61.8 | 16.5 / 16.5 |
| 850/80 | 823.5 / 70.5 | 20.3 / 30.0 |
| 850/90 | 832.2 / 80.6 | 17.9 / 18.5 |
| 900/70 | 875.4 / 61.5 | 19.1 / 26.0 |
| 900/80 | 851.4 / 69.6 | 28.5 / 48.9 |
| 900/90 | 876.9 / 80.1 | 20.0 / 22.7 |

Direction-only repetitions showed no sustained CAKE-side climb: 800/850/900
download averaged 777/830/866Mbps at ~19ms median p95, while 70/80/90 upload
averaged 66.4/77.8/87.4Mbps at 11.3/8.0/8.1ms median p95. One 70Mbps upload run
fell to 63.6Mbps and ramped to 144ms p95 while router/modem and poenttoe latency
stayed low, consistent with a brief bottleneck beyond CAKE.

Two-minute simultaneous finalists:

| Cap ↓/↑ Mbps | Average received ↓/↑ Mbps | Google p95 median / maximum ms |
|---|---|---|
| 800/80 | 786.1 / 71.7 | 13.4 / 13.5 |
| 850/90 | 825.2 / 79.8 | 26.7 / 36.3 |
| 900/90 | 881.9 / 80.5 | 18.9 / 19.7 |

For good conditions, 900/90 is the maximum-throughput choice: it retained ~98%
of the unshaped simultaneous download and ~90% of upload without p95 climbing
above adjacent idle measurements. 800/80 is the lower-tail choice, giving up
~96/9Mbps for ~5.5ms lower p95 and tighter p99. Across all six short/long 900/90
runs, combined Google+Cloudflare probe loss was 0.10%; across eight 800/80 runs
it was 0.07%.

Other measured LAN traffic was <=0.6/0.45Mbps in the randomized grid and
<=0.19/0.06Mbps in finalist load runs. Poenttoe retained >=38% CPU idle in the
grid and >=68% in finalists; its Cloudflare p95 was 1.53ms. DOCSIS stayed online,
downstream SNR 41–43dB, upstream power 40.5–41dBmV, downstream power 0.3–4dBmV,
and downstream error counters did not increase. Estimated transfer including
accounting margin was 361.65GB. Restored CAKE disabled at 800/80; all final
Terraform plans were empty. Transmission restart remains pending. Raw roots:
`cake-good-conditions-1789336365`, `cake-good-grid-1789337349`,
`cake-good-directional-1789339769`, and `cake-good-finalists-1789341652`.

### 2026-09-14 — Reactive 650/50 monitor

The randomized 650/50 run recorded 11 simultaneous trials, 3 flags, and 26.12GB.
Its worst event delivered 351.9/13.5Mbps and raised Google p95 by ~247ms while
router, modem-management, CAKE, client, server, and competing-WAN measurements
remained healthy. This places the transient bottleneck beyond the router but does
not distinguish the modem data path, CMTS, ISP, or route.

The replacement monitor runs every 7–13 minutes. A flagged simultaneous trial
immediately triggers upload-only, download-only, then simultaneous retests; the
directional order alternates between incidents. Each probe has 15 seconds idle,
30 seconds load, and 15 seconds recovery. It ended with 15 main trials, 9 flags,
27 diagnostics, and 77.49GB transferred. Upload-only remained near 48Mbps while
download-only varied from roughly 527–613Mbps; simultaneous retests sometimes
recovered and sometimes remained degraded. Raw roots on pannu:
`cake-day-monitor-650-50-randomized-20260914` and
`cake-day-monitor-650-50-reactive-20260914`.

### 2026-09-14 — Reactive 500/50 monitor

Lowered stationary CAKE to 500/50 through Terraform and retained kuberack at
800/80. The 24-hour reactive protocol uses thresholds of 450Mbps down, 42Mbps
up, and +10ms internet p95. The stopped run recorded 137 main trials, 20 flags,
60 diagnostics, no execution failures, and 344.11GB transferred. Median received
throughput was 491.4/44.8Mbps; 16 trials crossed the latency threshold and 5
crossed +30ms. Available capacity still occasionally fell below the shaper.
Raw root on pannu:
`cake-day-monitor-500-50-reactive-20260914`.

### 2026-09-16 — Permanent CAKE setting

Selected HTB-backed CAKE at 500/50Mbps as the practical static compromise and
moved the limits from the ignored experiment override into tracked Terraform.
The full plan reported no changes, confirming the live router already matched.
