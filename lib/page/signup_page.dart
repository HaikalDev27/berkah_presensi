import 'package:flutter/material.dart';
class SignUp extends StatefulWidget {
	const SignUp({super.key});
	@override
	SignUpState createState() => SignUpState();
}
class SignUpState extends State<SignUp> {
	String textField1 = '';
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: IntrinsicHeight(
									child: Container(
										color: Color(0xFFFFFFFF),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											padding: const EdgeInsets.only( top: 316),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															width: double.infinity,
															child: Stack(
																clipBehavior: Clip.none,
																children: [
																	Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(40),
																						color: Color(0xFFFFFFFF),
																					),
																					padding: const EdgeInsets.only( top: 37),
																					width: double.infinity,
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							IntrinsicHeight(
																								child: Container(
																									margin: const EdgeInsets.only( bottom: 19, left: 45, right: 45),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Container(
																												margin: const EdgeInsets.only( bottom: 4, left: 6),
																												child: Text(
																													"Username",
																													style: TextStyle(
																														color: Color(0xFF000000),
																														fontSize: 20,
																													),
																												),
																											),
																											IntrinsicHeight(
																												child: Container(
																													decoration: BoxDecoration(
																														borderRadius: BorderRadius.circular(15),
																														color: Color(0xFFD9D9D9),
																													),
																													padding: const EdgeInsets.only( top: 15, bottom: 15, left: 42),
																													width: double.infinity,
																													child: Column(
																														crossAxisAlignment: CrossAxisAlignment.start,
																														children: [
																															Text(
																																"Enter your username",
																																style: TextStyle(
																																	color: Color(0xFFAF9F9F),
																																	fontSize: 18,
																																),
																															),
																														]
																													),
																												),
																											),
																										]
																									),
																								),
																							),
																							IntrinsicHeight(
																								child: Container(
																									margin: const EdgeInsets.only( bottom: 21, left: 44, right: 44),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Container(
																												margin: const EdgeInsets.only( bottom: 4, left: 6),
																												child: Text(
																													"NIK",
																													style: TextStyle(
																														color: Color(0xFF000000),
																														fontSize: 20,
																													),
																												),
																											),
																											IntrinsicHeight(
																												child: Container(
																													alignment: Alignment.center,
																													decoration: BoxDecoration(
																														borderRadius: BorderRadius.circular(15),
																														color: Color(0xFFD9D9D9),
																													),
																													width: double.infinity,
																													child: TextField(
																														style: TextStyle(
																															color: Color(0xFFAF9F9F),
																															fontSize: 18,
																														),
																														onChanged: (value) { 
																															setState(() { textField1 = value; });
																														},
																														decoration: InputDecoration(
																															hintText: "Enter your NIK",
																															isDense: true,
																															contentPadding: const EdgeInsets.only( top: 15, bottom: 15, left: 43, right: 43),
																															border: InputBorder.none,
																															focusedBorder: InputBorder.none,
																															filled: false,
																														),
																													),
																												),
																											),
																										]
																									),
																								),
																							),
																							IntrinsicHeight(
																								child: Container(
																									margin: const EdgeInsets.only( bottom: 47, left: 45, right: 45),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Container(
																												margin: const EdgeInsets.only( bottom: 4, left: 6),
																												child: Text(
																													"Password",
																													style: TextStyle(
																														color: Color(0xFF000000),
																														fontSize: 20,
																													),
																												),
																											),
																											IntrinsicHeight(
																												child: Container(
																													decoration: BoxDecoration(
																														borderRadius: BorderRadius.circular(15),
																														color: Color(0xFFD9D9D9),
																													),
																													padding: const EdgeInsets.symmetric(vertical: 13),
																													width: double.infinity,
																													child: Row(
																														mainAxisAlignment: MainAxisAlignment.spaceBetween,
																														children: [
																															Container(
																																margin: const EdgeInsets.only( left: 42),
																																child: Text(
																																	"Enter your password",
																																	style: TextStyle(
																																		color: Color(0xFFAF9F9F),
																																		fontSize: 18,
																																	),
																																),
																															),
																															Container(
																																margin: const EdgeInsets.only( right: 10),
																																width: 30,
																																height: 30,
																																child: Image.network(
																																	"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/noR02UYlwt/f8k1igvb_expires_30_days.png",
																																	fit: BoxFit.fill,
																																)
																															),
																														]
																													),
																												),
																											),
																										]
																									),
																								),
																							),
																							IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										color: Color(0xFFFFFFFF),
																										boxShadow: [
																											BoxShadow(
																												color: Color(0x40000000),
																												blurRadius: 5,
																												offset: Offset(2, 4),
																											),
																										],
																									),
																									margin: const EdgeInsets.only( bottom: 122, left: 45, right: 45),
																									width: double.infinity,
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											InkWell(
																												onTap: () { print('Pressed'); },
																												child: IntrinsicHeight(
																													child: Container(
																														decoration: BoxDecoration(
																															borderRadius: BorderRadius.circular(15),
																															gradient: LinearGradient(
																																begin: Alignment(-1, -1),
																																end: Alignment(-1, 1),
																																colors: [
																																	Color(0xFF42D883),
																																	Color(0xFF237245),
																																],
																															),
																														),
																														padding: const EdgeInsets.symmetric(vertical: 12),
																														margin: const EdgeInsets.only( bottom: 15),
																														width: double.infinity,
																														child: Column(
																															children: [
																																Text(
																																	"Sign Up",
																																	style: TextStyle(
																																		color: Color(0xFFFFFFFF),
																																		fontSize: 23,
																																		fontWeight: FontWeight.bold,
																																	),
																																),
																															]
																														),
																													),
																												),
																											),
																											IntrinsicWidth(
																												child: IntrinsicHeight(
																													child: Container(
																														margin: const EdgeInsets.only( left: 22, right: 38),
																														width: double.infinity,
																														child: Row(
																															children: [
																																Container(
																																	margin: const EdgeInsets.only( right: 9),
																																	child: Text(
																																		"Already have an account?",
																																		style: TextStyle(
																																			color: Color(0xFF000000),
																																			fontSize: 15,
																																		),
																																	),
																																),
																																Text(
																																	"Sign In >",
																																	style: TextStyle(
																																		color: Color(0xFF2BF399),
																																		fontSize: 15,
																																	),
																																),
																															]
																														),
																													),
																												),
																											),
																										]
																									),
																								),
																							),
																						]
																					),
																				),
																			),
																		]
																	),
																	Positioned(
																		top: 0,
																		left: 0,
																		right: 0,
																		height: 388,
																		child: Container(
																			transform: Matrix4.translationValues(0, -316, 0),
																			height: 388,
																			width: double.infinity,
																			child: SizedBox(),
																		),
																	),
																	Positioned(
																		top: 0,
																		left: 0,
																		right: 0,
																		child: IntrinsicHeight(
																			child: Container(
																				decoration: BoxDecoration(
																					gradient: LinearGradient(
																						begin: Alignment(-1, -1),
																						end: Alignment(-1, 1),
																						colors: [
																							Color(0xFF75F3BB),
																							Color(0xDB2A6D51),
																						],
																					),
																				),
																				padding: const EdgeInsets.only( top: 26),
																				transform: Matrix4.translationValues(0, -316, 0),
																				width: double.infinity,
																				child: Column(
																					children: [
																						Container(
																							margin: const EdgeInsets.only( bottom: 16),
																							child: Text(
																								"PT. Berkah Gobal Business",
																								style: TextStyle(
																									color: Color(0xFFFFFFFF),
																									fontSize: 16,
																									fontWeight: FontWeight.bold,
																								),
																							),
																						),
																						IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									margin: const EdgeInsets.only( bottom: 98),
																									child: Column(
																										children: [
																											Container(
																												width: 165,
																												height: 165,
																												child: Image.network(
																													"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/noR02UYlwt/get6yzbp_expires_30_days.png",
																													fit: BoxFit.fill,
																												)
																											),
																											Text(
																												"Sign Up",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 40,
																													fontWeight: FontWeight.bold,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					]
																				),
																			),
																		),
																	),
																]
															),
														),
													),
												],
											)
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}
}