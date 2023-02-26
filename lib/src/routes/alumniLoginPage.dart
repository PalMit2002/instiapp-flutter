import 'package:flutter/material.dart';

import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';

class AlumniLoginPage extends StatefulWidget {
  const AlumniLoginPage({Key? key}) : super(key: key);

  @override
  _AlumniLoginPageState createState() => _AlumniLoginPageState();
}

class _AlumniLoginPageState extends State<AlumniLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  InstiAppBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of(context)!.bloc;
    return Scaffold(
      drawer: const NavDrawer(),
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Alumni Login'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: <Widget>[
            const SizedBox(
              height: 10.0,
            ),
            TextFormField(
              validator: (String? valueEnt) {
                if (valueEnt == null || valueEnt.isEmpty
                    // || !valueEnt.contains("@")
                    ) {
                  return 'Please enter the correct LDAP';
                }
                return null;
              },
              initialValue: '',
              decoration: const InputDecoration(labelText: 'Enter your LDAP here.'),
              onChanged: (String value) => {
                setState(() => {_bloc!.setAlumniID(value)})
              },
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: const Text('Send OTP'),
              onPressed: () async {
                await _bloc!.updateAlumni();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_bloc!.msg),
                ));

                if (_formKey.currentState!.validate() && _bloc!.isAlumni) {
                  await Navigator.popAndPushNamed(context, '/alumni-OTP-Page',
                      arguments: {
                        'ldap': _bloc!.alumniID,
                        // "isAlumni": _bloc!.isAlumni,
                        // "msg": _bloc!.msg
                      });
                }

                // print(_bloc!.alumniID);
                // print(_bloc!.isAlumni);
              },
            ),
          ]),
        ),
      ),
    );
  }
}
