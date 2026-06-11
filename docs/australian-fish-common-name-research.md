# Australian Fish Common Name Research

This note records the source trail used for `afma-006` common-name seeding and `afma-008` visual reports.

## Source Pattern

- Use CSIRO CAAB as the canonical species key and scientific-name source.
- Use `fish.gov.au` and the Australian Fish Names Database as the national common-name reference trail.
- Use FRDC Fishfiles and AFMA fishery pages to make Australian regions, landing ports, and fishery context feel realistic.
- Mark curated local or market aliases as demo/reference/synthetic data; do not present them as AFMA production records.

## National References

- `fish.gov.au` is the FRDC Status of Australian Fish Stocks reporting site. It states that the reports bring together biological, catch, and effort information for Australian fish stocks and that the reports cover 155 Australian species and 503 stocks: <https://fish.gov.au/>
- The same site points users looking for fish names to the Australian Fish Names Database: <https://www.fishnames.com.au/>
- Jurisdiction pages provide useful state-by-state lists of recognised finfish common names and scientific names:
  - New South Wales: <https://fish.gov.au/jurisdiction/new-south-wales>
  - Queensland: <https://fish.gov.au/jurisdiction/queensland>
  - Western Australia: <https://fish.gov.au/jurisdiction/western-australia>

## Fishery And Location References

- FRDC Fishfiles says it provides accurate and informative information on Australian sustainable seafood: <https://www.fishfiles.com.au/>
- NSW Ocean Trap and Line targets demersal and pelagic fish along the entire NSW coast and lists snapper, yellowtail kingfish, bonito, silver trevally, grey morwong, blue-eye trevalla, sharks, bar cod, and yellowfin bream as key species: <https://www.fishfiles.com.au/fisheries-and-farms/nsw-fisheries-and-farms/ocean-trap-and-line-fishery>
- NT Wild Barramundi identifies Barramundi and King Threadfin as primary species, with Black Jewfish and Blue Threadfin among common byproduct species; it also provides the 1 February to 30 September season and Top End river/coast context: <https://www.fishfiles.com.au/fisheries-and-farms/nt-fisheries-and-farms/wild-barramundi-fishery>
- SA Marine Scalefish is a multi-species, multi-gear fishery in South Australian coastal waters, with King George Whiting, Southern Garfish, Snapper, and Southern Calamari named as main species: <https://www.fishfiles.com.au/fisheries-and-farms/sa-fisheries-and-farms/marine-scale-fishery>
- WA West Coast Demersal Scale Fish Resource lists West Australian Dhufish, Snapper, Redthroat Emperor, Bight Redfish, Baldchin Groper, Hapuku, Blue-eye Trevalla, and Eightbar Grouper as indicator species: <https://www.fishfiles.com.au/fisheries-and-farms/wa-fisheries-and-farms/west-coast-demersal-scale-fish-resource>
- Queensland Commercial Line Fisheries describe coral reef, rocky reef, pelagic, Gulf of Carpentaria, and deepwater line fisheries; dominant catches include Coral Trout, Spanish Mackerel, and Redthroat Emperor: <https://www.fishfiles.com.au/fisheries-and-farms/qld-fisheries-and-farms/commercial-line-fisheries>

## AFMA/Commonwealth Context

- AFMA's fisheries map page lists major Commonwealth fisheries such as Eastern Tuna and Billfish, Southern and Eastern Scalefish and Shark, Southern Bluefin Tuna, Small Pelagic, Western Tuna and Billfish, and Western Deepwater Trawl: <https://www.afma.gov.au/commercial-fishers/management-arrangements/fisheries-maps>
- Eastern Tuna and Billfish extends from Cape York in Queensland to the South Australian/Victorian border, with major landing ports including Cairns, Mooloolaba, Southport, Coffs Harbour, Ulladulla, and Bermagui: <https://www.afma.gov.au/fisheries/eastern-tuna-and-billfish-fishery>
- Southern and Eastern Scalefish and Shark covers almost half of the Australian Fishing Zone and stretches from Fraser Island, around Tasmania, to Cape Leeuwin: <https://www.afma.gov.au/fisheries/southern-and-eastern-scalefish-and-shark-fishery>
- Southern Bluefin Tuna covers the entire sea area around Australia out to 200 nautical miles and lists Port Lincoln, Ulladulla, and Bermagui as major landing ports: <https://www.afma.gov.au/fisheries/southern-bluefin-tuna-fishery>
- Western Tuna and Billfish covers the sea area west from Cape York, around Western Australia, to the Victoria/South Australia border: <https://www.afma.gov.au/fisheries/western-tuna-and-billfish-fishery>

## Seed Data Guidance

Use examples that fishers and seafood buyers would recognise, but preserve provenance:

- `CSIRO_PRIMARY` and `CSIRO_ALT` come from the CAAB workbook columns.
- `STANDARD` uses national or jurisdiction common-name references.
- `LOCAL_ALIAS` captures region-linked names such as `barra`, `kingie`, `flatty`, `dhuie`, `greenback`, and `threadie`.
- `MARKET_ALIAS` captures seafood counter terms such as `flake`, with notes when the term is ambiguous.
- `LEGACY_ALIAS` captures older or ambiguous names that should not be treated as preferred modern names.
- `SYNTHETIC_DEMO` is allowed only where the value is intentionally demo-curated and clearly marked as synthetic.
