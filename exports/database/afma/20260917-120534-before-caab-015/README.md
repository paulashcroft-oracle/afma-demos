# AFMA package source before caab-015

Captured 17 September 2026 through native APEX SQL Commands, signed in as CODEX,
workspace and selected schema AFMA, AIDEMODB / APEX 26.1.4. This supplements the
app 101 baseline `exports/apex/afma/101/20260917-110915-before-caab-015`.

The four files contain the exact ordered `ALL_SOURCE.TEXT` values, without added
SQL client commands. The native UTF-8 CSV returned 1,112 rows. Each group has
contiguous line numbers from 1 through its reported final line; reconstructed
character counts equal the independent database aggregation.

| Object | Type | Lines | Characters | SHA-256 |
| --- | --- | ---: | ---: | --- |
| CSIRO_CAAB_AGENT_API | PACKAGE | 16 | 399 | 17BC9335E8028F81FB885D531A4FE434F16367EAC089D5C3978ED4F359926FB8 |
| CSIRO_CAAB_AGENT_API | PACKAGE BODY | 883 | 34588 | 6AF45EB82D5210EA677DBA751EF2CED2EC8FB2BAB20F60B79064CAE7EE3501EA |
| CSIRO_CAAB_PAGE_API | PACKAGE | 4 | 127 | 41FA7B4146C67206D03C100B52E811A5B15C30563C0707D3291F05CF18922524 |
| CSIRO_CAAB_PAGE_API | PACKAGE BODY | 209 | 26410 | E092B2E710C9A3953063AD20EB077F88C101DE5B6A908FD1085DD9699F7B5A9A |

Query: `select name,type,line,text from all_source where owner='AFMA' and name
in ('CSIRO_CAAB_AGENT_API','CSIRO_CAAB_PAGE_API') and type in ('PACKAGE','PACKAGE
BODY') order by name,type,line`. Independent totals used `count(*)`, `min(line)`,
`max(line)` and `sum(length(text))` grouped by name and type.

Native download began at 12:05:34.852 UTC. The observed `report.csv` download
completed at 107,130 bytes; the concrete file was created 12:05:36.370 UTC and
written 12:05:36.981 UTC. SHA-256 before/after exact-file relocation:
`02B6EF40B70CB4824D2E799A64B23E4319DA5DB8A4E42E1456B7E036B226716A`.
It is retained in the owned private run as
`afma-packages-20260917T120534-before.csv`, with review on 17 October 2026.
No other Downloads file was touched.

Independent comparison against candidate parent `61f0c5f^` found identical line
counts and characters except one trailing ASCII space on each non-final source
line. Inspection of multiline quoted SQL/PLSQL found no behavioral change.
Both captured specifications match the candidate public interfaces. No semantic
drift requires merging before body-only delivery. A secret/session-pattern scan
found no forbidden material. Native trailing whitespace is deliberately preserved
in these four exact source captures; it is not a formatting change to the candidate.

For an authorized rollback, prefix a selected file's complete text with
`create or replace ` and append a standalone `/` for SQL Scripts/SQLcl. Use the
AFMA parsing schema, preserve the matching spec, and verify validity/errors and
runtime behavior. These sources contain no application metadata and do not
authorize an application replacement or data reload.
