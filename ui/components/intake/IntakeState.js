// Pure presentation helpers; backend authorization remains authoritative.
function details(item) {
    var value = item && item.extensions && item.extensions["io.miilo.intake"];
    return value && value.version === 1 ? value : null;
}
function available(item, action) {
    if (!details(item)) return false;
    return (item.actions || []).some(function(a) { if (a.id !== "intake." + action || a.available !== true || a.confirmation === "strong") return false;
        var required = a.inputSchema && a.inputSchema.required || [];
        return Array.isArray(required) && required.every(function(key) { return action === "defer" && key === "until"; }); });
}
function command(item, action, requestId, confirmedAt, until) {
    if (!available(item, action)) throw new Error("Action unavailable; refresh the inbox");
    var args = ["decide", item.providerId + "/" + item.id, "--action", action,
        "--revision", item.revision, "--request-id", requestId, "--confirmed-at", confirmedAt];
    if (action === "defer") args.push("--until", until);
    return args;
}
function label(item) {
    var value = details(item);
    if (!value) return "Unsupported intake version";
    if (value.decision === "accepted") return String(value.execution).replace(/_/g, " ");
    return value.decision === "pending" ? "Needs you" : value.decision;
}

// Conservative local intent resolution. No model can grant a new capability.
function resolve(text, items) {
    if (typeof text !== "string" || text.length > 4000) return {handled:false};
    var match = /^(?:please\s+)?(accept|defer|dismiss|later)(?:\s+(.+?))?[.!]?$/i.exec(text.trim());
    if (!match) return {handled:false};
    var action = /^(later|defer)$/i.test(match[1]) ? "defer" : match[1].toLowerCase();
    var target = (match[2] || "").replace(/[.!]$/, "").trim().toLowerCase();
    var candidates = items.filter(function(item) {
        if (!available(item, action)) return false;
        var source = details(item).source || {};
        return !target || target === "it" || target === "that" ||
            String(item.id).toLowerCase() === target || String(source.externalId || "").toLowerCase() === target ||
            (String(details(item).workflowId) + "/" + String(source.externalId)).toLowerCase() === target ||
            (String(source.connectionId) + "/" + String(source.externalId)).toLowerCase() === target ||
            String(item.title).toLowerCase() === target;
    });
    return candidates.length === 1 ? {handled:true,item:candidates[0],action:action} :
        {handled:true,message:candidates.length ? "Which task? Say its identifier or title." : "No available task matches that decision."};
}

function safeLink(url) { return typeof url === "string" && /^https:\/\//i.test(url) && !/[\s\x00-\x1f]/.test(url); }
function reference(item) {
    var value = details(item);
    return value && value.source ? String(value.workflowId) + " / " + String(value.source.externalId) : "";
}
