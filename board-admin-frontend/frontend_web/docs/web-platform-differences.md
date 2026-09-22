# Web platform differences

- Browsers cannot guarantee screenshot or screen-recording prevention. Protected documents still depend on authorization, short-lived URLs and server policy.
- Browser storage is not equivalent to Flutter secure storage. The current token design uses `localStorage`; an HTTP-only, Secure, SameSite cookie is recommended when backend changes are permitted.
- A generated installation UUID identifies a browser installation for the existing login contract. It is not a hardware identity or security-grade fingerprint.
- Local mobile notifications are represented by the in-app notification drawer. Browser push is not enabled because no push-subscription API contract exists.
- Protected PDFs are not cached offline by default. Browser Cache Storage/IndexedDB support requires an explicit retention and encryption policy.
- Microphone access is requested only while creating a voice annotation and is subject to browser permission and HTTPS requirements.
- Web drawing and markup annotations use append-only `WEB_OVERLAY_V1` events with normalized coordinates. Flutter's Syncfusion editor embeds equivalent markup in PDF bytes, so Flutter requires a matching overlay renderer to display web-created markup.
