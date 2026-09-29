# /gr 2026-09-29: the rifle camera's FOV (20 -> 26.23) is not REFramework's doing, unless it became primary

Answers dossier §9cr question 3 (from `external-research/inbox/2026-09-26-mod-what-makes-re8-draw-a-second-camera.md`).
REFramework's VR mod sets FOV/aspect every frame only on `via.SceneView.get_PrimaryCamera`; its projection override
applies to every camera, its view override only to the primary one `[inferred-static 2026-09-29]`. Cheap live
check: read `get_PrimaryCamera` while the rifle camera exists. Topic:
`external-research/topics/2026-09-29-reframework-writes-fov-only-on-the-primary-camera.md`. Questions 1-2 (a public
TDB-70 render-to-texture example) were not found.
