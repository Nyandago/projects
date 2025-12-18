import 'package:flutter/material.dart';

import 'contract_linking.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ContractLinking contractLinking;
  List candidates = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    contractLinking = ContractLinking();
    loadCandidates();
  }

  Future<void> loadCandidates() async {
    candidates = await contractLinking.getCandidates();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Voting DApp'),),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            ElevatedButton(
              onPressed: () => contractLinking.connectWallet(context),
              child: Text('Connect Wallet'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(candidates[index]['name']),
                    subtitle: Text('Votes: ${candidates[index]['votes']}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await contractLinking.vote(index);
                        loadCandidates();
                      },
                      child: Text('Vote'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}