import 'package:flutter/material.dart';

import '../bloc_provider.dart';
import '../blocs/ia_bloc.dart';
import '../drawer.dart';

class AlumniOTPPage extends StatefulWidget {
  const AlumniOTPPage({Key? key}) : super(key: key);

  @override
  _AlumniOTPPageState createState() => _AlumniOTPPageState();
}

class _AlumniOTPPageState extends State<AlumniOTPPage> {
  InstiAppBloc? _bloc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  dynamic routedData = {};

  @override
  Widget build(BuildContext context) {
    routedData = ModalRoute.of(context)!.settings.arguments;
    // print(routedData);
    _bloc = BlocProvider.of(context)!.bloc;
    _bloc!.setAlumniID(routedData['ldap'].toString());
    // print(_bloc!.alumniID);

    return Scaffold(
      drawer: const NavDrawer(),
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Alumni Login -OTP'),
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
                /*||_bloc!.alumniKey.length != _bloc!.alumniPassword.length*/

                if (valueEnt == null ||
                    valueEnt.isEmpty ||
                    _bloc!.alumniOTP.isEmpty) {
                  return 'Please enter the correct OTP';
                }
                return null;
              },
              initialValue: '',
              decoration:
                  const InputDecoration(labelText: 'Enter the OTP here.'),
              onChanged: (String value) => {
                setState(() => {_bloc!.setAlumniOTP(value)})
              },
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: const Text('Verify OTP'),
              onPressed: () async {
                await _bloc!.logAlumniIn(false);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_bloc!.msg),
                ));

                if (_formKey.currentState!.validate() && _bloc!.isAlumni) {
                  // await _bloc!.reloadCurrentUser();
                  await Navigator.pushNamedAndRemoveUntil(
                      context, _bloc!.homepageName, (Route r) => false);
                }

                // print(_bloc!.alumniOTP.length);
              },
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: const Text('Resend OTP'),
              onPressed: () async {
                await _bloc!.logAlumniIn(true);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_bloc!.msg),
                ));
              },
            ),
          ]),
        ),
      ),
    );
  }
}
