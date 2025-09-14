@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  if (isConnecting) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );
  }

  return Scaffold(
    appBar: AppBar(title: const Text("🤖 EVEN AI")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ BLE Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: connectedDevice != null ? Colors.green.shade900 : Colors.red.shade900,
            child: Text(
              connectedDevice != null
                  ? "🟢 Connected to ${connectedDevice!.name.isNotEmpty ? connectedDevice!.name : connectedDevice!.id}"
                  : "🔴 Not Connected",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ✅ Query input
          TextField(
            controller: _controller,
            style: theme.textTheme.bodyLarge,
            cursorColor: Colors.greenAccent,
            decoration: const InputDecoration(
              hintText: "Ask me anything...",
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Send button
          ElevatedButton(
            onPressed: sendQuery,
            child: const Text("SEND"),
          ),
          const SizedBox(height: 24),

          // ✅ AI Response
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                response,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}